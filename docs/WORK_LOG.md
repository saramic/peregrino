# WORK LOG

# Fri 26 June 2026

### 6 Local database setup

Migrate to use UUIDs by default

1. Migration to enable the extension:

   ``` sh
   bin/rails generate migration EnableUuid
   ```

   ```ruby
   def change
     enable_extension "pgcrypto"
   end
   ```
2. Set UUID as default primary key in config/application.rb:

   ```ruby
   config.generators do |g|
     g.orm :active_record, primary_key_type: :uuid
   end
   ```

```bash
bin/rails db:create db:migrate
bin/rails db:seed
```

### 7 Confirm it runs

```bash
bin/dev   # starts Puma + Tailwind watcher via Procfile.dev
# visit http://localhost:3000
```

### 8 Add fearture specs

```sh
bundle add \
  capybara \
  rspec-example_steps \
  selenium-webdriver \
  rubocop-capybara
```

- setup capybara `spec/support/capybara.rb`
- setup example_steps gem `spec/support/example_steps.rb`
- create a basic feature `spec/features/it_works_spec.rb`
- based on the welcome route `get "test_root", to: "rails/welcome#index"`

#### Site prism for page object abstraction

```sh
bundle add \
  site_prism --group test
```

- add a first page object model `spec/support/pages/it_works_root.rb`

# Tue 16 June 2026

## 1. Setup tools and build

```sh
mise use ruby 4.0.5

# create Makefile and mise.toml

make check
# which runs
mise run check

# also have
mise run install
mise run check-tools
mise run setup
```

added a CI step via github actions
- [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

## 2. Rails New

with:

```sh
# From inside your peregrino/ repo root:
rails new . \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --javascript=esbuild \
  --css=tailwind \
  --skip-action-mailbox \
  --skip-action-text \
  --skip-jbuilder \
  --skip-test \
  --skip

# --skip tells Rails not to overwrite existing files without asking.
# Your README.md and LICENSE are preserved.
# Check the diff carefully before committing — Rails generates its own
# README stub that --skip will leave alone, but verify nothing important
# was clobbered.
```

### Why esbuild over importmap?

Bridge Components for Hotwire Native benefit from a proper build step —
tree-shaking, TypeScript support, and normal `pnpm add` for JS packages without
going through importmap's CDN pinning workflow. esbuild adds a ~2s build step
in CI. It is the right call for growing a JS surface for this app.

### Why these flags?

Solid Queue, Solid Cache, Solid Cable, and Kamal are included by default in
Rails 8 — no extra flags needed. `--skip-test` lets you drop in RSpec cleanly.
`--skip-jbuilder` because we serve HTML not JSON to mobile (Hotwire Native).
`--skip-action-mailbox` and `--skip-action-text` are almost never used on
a new project; add them back if needed.

### 3. Switch to PNPM

Install and check versions of `pnpm` and `node`

```sh
mise use pnpm@10
mise use node@24
```

update rails to use `pnpm`

```sh
# Remove any yarn.lock or package-lock.json Rails may have created
rm -f yarn.lock package-lock.json

# Fix Procfile.dev — Rails generates: js: yarn build --watch
# Change to pnpm:
sed -i '' 's/yarn build/pnpm build/g' Procfile.dev

# Install with pnpm (generates pnpm-lock.yaml)
pnpm install

# Verify the bridge package installs cleanly
pnpm add @hotwired/hotwire-native-bridge
```

### 4. RSpec for testing

base testing setup

```sh
bundle add rspec-rails --group "development, test"
bin/rails generate rspec:install
bundle binstub rspec-core

bin/rspec

# run in check
make check
```

### 5. Rubocop for ruby linting

seems like this is somewhat setup already

```sh
bundle exec rubocop
# now part of
make check
```

### 6. ESLint + Prettier

Add linting for the JavaScript side — bridge components, Lambda functions, and
any future TypeScript. A shared config at the root covers all three.

```bash
# Install at repo root
pnpm add -D eslint @eslint/js eslint-plugin-import prettier \
  eslint-config-prettier eslint-plugin-prettier
```

Create eslint.config.js at repo root (ESLint flat config format, the default since ESLint 9):

Create `.prettierrc` at repo root:

```json
{
  "semi": false,          # no longer needed as ASI (Automatic Semicolon Insertion fixes it)
  "singleQuote": true,    # becuase more Rails like but not like JSON
  "trailingComma": "es5", # because all will put into functions as well
  "printWidth": 100       # because 80 is too tight
}
```

talked AI down and just went for `.prettierrc` as below

```json
{}
```

added `pnpm lint` and `pnpm format` scrits

---
UP TO HERE
---

# WORK_LOG — Monorepo setup: Rails + Lambdas + Hotwire Native

### X.X Fix Solid Stack + PostgreSQL (known Rails 8 gotcha)

> **NOTE:** skipping as this seems to not be necessary, leaving for when we deploy

Rails 8 generates `config/database.yml` expecting four separate databases for
Solid Queue, Cache, Cable. With a single `DATABASE_URL` env var, the secondary
connections silently fail. Fix it now before first deploy.

```bash
# Run the install generators (idempotent — safe to run on a fresh app)
bin/rails solid_cache:install
bin/rails solid_queue:install
bin/rails solid_cable:install
```

Edit `config/database.yml` — the production block should look like this:

```yaml
production:
  primary: &primary_production
    <<: *default
    url: <%= ENV["PRIMARY_DATABASE_URL"] %>
  cache:
    <<: *primary_production
    database: my_app_production_cache
    url: <%= ENV["CACHE_DATABASE_URL"] %>
    database_tasks: true
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    database: my_app_production_queue
    url: <%= ENV["QUEUE_DATABASE_URL"] %>
    database_tasks: true
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    database: my_app_production_cable
    url: <%= ENV["CABLE_DATABASE_URL"] %>
    database_tasks: true
    migrations_paths: db/cable_migrate
```

> In production with a single RDS instance you point all four URLs at the same
> host with different database names. In local dev, SQLite is fine for the
> secondary databases — Rails handles this automatically.

```bash
git add . && git commit -m "fix solid stack postgres database.yml"
```


## Phase 2 — Repo structure

### 2.1 Create sibling directories

```bash
mkdir -p lambdas/shared
mkdir -p lambdas/audio-processor
mkdir -p lambdas/geo-trigger
mkdir -p mobile          # Xcode and Android Studio projects go in here (Phase 5+)
mkdir -p infra
mkdir -p doc/adr
```

### 2.2 Root-level developer tooling

#### pnpm-workspace.yaml

Create `pnpm-workspace.yaml` at repo root so lambdas share a single lockfile
and `pnpm install` at the root installs everything:

```yaml
packages:
  - 'lambdas/*'
```

#### Makefile

Create `Makefile` at repo root:

```makefile
.PHONY: setup test lint deploy-lambdas open-ios open-android

setup:
	bundle install
	pnpm install
	bin/rails db:prepare

test:
	bin/rails spec
	pnpm --filter '*' test

lint:
	bundle exec rubocop
	pnpm lint

deploy-lambdas:
	pnpm --filter '*' exec serverless deploy --stage production

open-ios:
	open mobile/ios/Peregrino.xcodeproj

open-android:
	open -a "Android Studio" mobile/android
```

#### docker-compose.yml

Create `docker-compose.yml` at repo root for local development:

```yaml
services:
  web:
    build: .
    command: bin/dev
    volumes:
      - .:/rails
      - bundle:/usr/local/bundle
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgres://postgres:password@postgres:5432/my_app_development

  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      SERVICES: s3,sqs,lambda
      AWS_DEFAULT_REGION: ap-southeast-2

volumes:
  bundle:
  pgdata:
```

```bash
git add . && git commit -m "add repo structure, Makefile, docker-compose"
```

### 2.3 ADR directory

```bash
cp path/to/adr-0001-template.adoc doc/adr/0001-architecture-decision-record-template.adoc
cp path/to/adr-0002-monorepo.adoc doc/adr/0002-monorepo-rails-lambda-hotwire-native.adoc
git add . && git commit -m "add ADRs"
```

---

## Phase 3 — Secrets management

We use **AWS Secrets Manager** as the source of truth and Kamal's built-in
secrets adapter to pull them at deploy time. No secrets are ever committed to
the repo. `.kamal/secrets` is in `.gitignore`.

### 3.1 Confirm .gitignore

```bash
# These should already be ignored — verify:
grep -E "master\.key|\.kamal/secrets" .gitignore

# If not, add:
echo "config/master.key" >> .gitignore
echo ".kamal/secrets" >> .gitignore
echo ".kamal/secrets.*" >> .gitignore
```

### 3.2 Create secrets in AWS Secrets Manager

```bash
# One-time setup — run locally with your AWS profile
AWS_PROFILE=myapp

# Rails master key (get value from config/master.key)
aws secretsmanager create-secret \
  --name "myapp/production/RAILS_MASTER_KEY" \
  --secret-string "$(cat config/master.key)" \
  --profile $AWS_PROFILE \
  --region ap-southeast-2

# Postgres password (choose a strong one)
aws secretsmanager create-secret \
  --name "myapp/production/POSTGRES_PASSWORD" \
  --secret-string "changeme-use-a-real-password" \
  --profile $AWS_PROFILE \
  --region ap-southeast-2

# Docker Hub / GHCR token for Kamal image registry
aws secretsmanager create-secret \
  --name "myapp/production/KAMAL_REGISTRY_PASSWORD" \
  --secret-string "your-registry-token-here" \
  --profile $AWS_PROFILE \
  --region ap-southeast-2

# Database URLs (staging and production, all four Solid Stack databases)
# Pattern: postgresql://user:password@rds-hostname:5432/dbname
aws secretsmanager create-secret \
  --name "myapp/production/PRIMARY_DATABASE_URL" \
  --secret-string "postgresql://myapp:password@myapp.xxxx.ap-southeast-2.rds.amazonaws.com:5432/myapp_production" \
  --profile $AWS_PROFILE \
  --region ap-southeast-2

# Repeat for CACHE_DATABASE_URL, QUEUE_DATABASE_URL, CABLE_DATABASE_URL
# (same host, different database name suffix)
```

### 3.3 Create staging secrets

```bash
# Repeat the above, replacing 'production' with 'staging' in the secret names
# e.g. "myapp/staging/RAILS_MASTER_KEY" — staging can share the same master.key
# but should have its own database credentials
```

### 3.4 Configure .kamal/secrets

Create `.kamal/secrets` (gitignored, for local deploys by developers):

```bash
# .kamal/secrets
# This file is generated — do not commit. Each developer maintains their own.
# It pulls from AWS Secrets Manager using the kamal secrets adapter.

SECRETS=$(kamal secrets fetch \
  --adapter aws_secrets_manager \
  --account myapp \
  --from myapp/production/ \
  RAILS_MASTER_KEY POSTGRES_PASSWORD KAMAL_REGISTRY_PASSWORD \
  PRIMARY_DATABASE_URL CACHE_DATABASE_URL QUEUE_DATABASE_URL CABLE_DATABASE_URL)

RAILS_MASTER_KEY=$(kamal secrets extract RAILS_MASTER_KEY $SECRETS)
POSTGRES_PASSWORD=$(kamal secrets extract POSTGRES_PASSWORD $SECRETS)
KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract KAMAL_REGISTRY_PASSWORD $SECRETS)
PRIMARY_DATABASE_URL=$(kamal secrets extract PRIMARY_DATABASE_URL $SECRETS)
CACHE_DATABASE_URL=$(kamal secrets extract CACHE_DATABASE_URL $SECRETS)
QUEUE_DATABASE_URL=$(kamal secrets extract QUEUE_DATABASE_URL $SECRETS)
CABLE_DATABASE_URL=$(kamal secrets extract CABLE_DATABASE_URL $SECRETS)
```

Create `.kamal/secrets.staging` for staging deploys (same pattern, different prefix):

```bash
SECRETS=$(kamal secrets fetch \
  --adapter aws_secrets_manager \
  --account myapp \
  --from myapp/staging/ \
  RAILS_MASTER_KEY POSTGRES_PASSWORD KAMAL_REGISTRY_PASSWORD \
  PRIMARY_DATABASE_URL CACHE_DATABASE_URL QUEUE_DATABASE_URL CABLE_DATABASE_URL)
# ... same extract lines
```

### 3.5 IAM policy for the deploy user

Create an IAM policy that allows only reading the `myapp/` prefix. Attach it
to the IAM user whose credentials developers and CI use.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "arn:aws:secretsmanager:ap-southeast-2:ACCOUNT_ID:secret:myapp/*"
    }
  ]
}
```

```bash
# Create the policy
aws iam create-policy \
  --policy-name myapp-secrets-reader \
  --policy-document file://infra/iam-secrets-reader-policy.json \
  --profile $AWS_PROFILE

# Attach to your deploy IAM user
aws iam attach-user-policy \
  --user-name myapp-deployer \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/myapp-secrets-reader \
  --profile $AWS_PROFILE
```

### 3.6 GitHub Actions secrets (for CI)

In your GitHub repo Settings → Secrets → Actions, add:

| Secret name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret |
| `AWS_REGION` | `ap-southeast-2` |

CI pulls Kamal secrets via AWS the same way a developer does — no
`RAILS_MASTER_KEY` is ever stored in GitHub secrets.

---

## Phase 4 — Kamal deployment

### 4.1 Configure config/deploy.yml

```yaml
service: myapp
image: your-dockerhub-username/myapp

registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD

servers:
  web:
    hosts:
      - YOUR_EC2_IP
    options:
      network: private
  jobs:
    hosts:
      - YOUR_EC2_IP
    cmd: bin/rails solid_queue:start
    options:
      network: private

proxy:
  ssl: true
  host: yourdomain.com

env:
  secret:
    - RAILS_MASTER_KEY
    - POSTGRES_PASSWORD
    - PRIMARY_DATABASE_URL
    - CACHE_DATABASE_URL
    - QUEUE_DATABASE_URL
    - CABLE_DATABASE_URL
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: true
    RAILS_SERVE_STATIC_FILES: true

accessories:
  postgres:
    image: postgres:16
    host: YOUR_EC2_IP
    port: 5432
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - pgdata:/var/lib/postgresql/data

builder:
  arch: amd64

aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell:   app exec --interactive --reuse "bash"
  logs:    app logs -f
  dbc:     app exec --interactive --reuse "bin/rails dbconsole"
```

### 4.2 Provision EC2 server

```bash
# Minimum: t3.small for staging, t3.medium for production
# Ubuntu 24.04 LTS, 20GB root volume
# Security groups: inbound 22 (your IP only), 80, 443

# SSH in and install Docker (Kamal does not install Docker for you)
ssh ubuntu@YOUR_EC2_IP

# On the server:
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker ubuntu
# log out and back in

# Back on your machine — bootstrap Kamal (first deploy only):
kamal setup
```

### 4.3 First deploy

```bash
kamal deploy
```

### 4.4 Staging deploy destination

Create `config/deploy.staging.yml`:

```yaml
servers:
  web:
    hosts:
      - YOUR_STAGING_EC2_IP
proxy:
  host: staging.yourdomain.com
env:
  clear:
    RAILS_ENV: staging
```

```bash
# Deploy to staging:
kamal deploy --destination staging
```

### 4.5 GitHub Actions CI/CD

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy-rails:
    if: |
      contains(github.event.commits[0].modified, 'app/') ||
      contains(github.event.commits[0].modified, 'config/') ||
      contains(github.event.commits[0].modified, 'db/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - uses: pnpm/action-setup@v4
        with:
          version: 10
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.DEPLOY_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan YOUR_EC2_IP >> ~/.ssh/known_hosts
      - name: Fetch Kamal secrets from AWS
        run: |
          SECRETS=$(kamal secrets fetch --adapter aws_secrets_manager \
            --account default --from myapp/production/ \
            RAILS_MASTER_KEY POSTGRES_PASSWORD KAMAL_REGISTRY_PASSWORD \
            PRIMARY_DATABASE_URL CACHE_DATABASE_URL QUEUE_DATABASE_URL CABLE_DATABASE_URL)
          # Write to .kamal/secrets (gitignored)
          # ... extract each and write
      - name: Deploy
        run: kamal deploy

  deploy-lambdas:
    if: contains(toJson(github.event.commits), 'lambdas/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 10
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}
      - run: pnpm --filter '*' exec serverless deploy --stage production
```

---

## Phase 5 — Lambda scaffolding

### 5.1 Lambda project init

With `pnpm-workspace.yaml` already set up at the repo root, each Lambda function
is a workspace package. Init from the repo root:

```bash
# Each Lambda gets its own package.json — pnpm links them via the workspace
cd lambdas/audio-processor
pnpm init
pnpm add @aws-sdk/client-s3 @aws-sdk/client-sqs

cd ../geo-trigger
pnpm init
pnpm add @aws-sdk/client-sns

# From repo root — installs all workspaces in one shot
cd ../..
pnpm install
```

### 5.2 Serverless Framework config

```bash
cd lambdas
pnpm add -D serverless serverless-esbuild esbuild
```

Create `lambdas/serverless.yml`:

```yaml
service: peregrino-lambdas
frameworkVersion: '4'

provider:
  name: aws
  runtime: nodejs24.x
  region: ap-southeast-2
  stage: ${opt:stage, 'development'}
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - s3:GetObject
            - s3:PutObject
          Resource: arn:aws:s3:::myapp-audio-${self:provider.stage}/*
        - Effect: Allow
          Action:
            - sqs:ReceiveMessage
            - sqs:DeleteMessage
          Resource: !GetAtt AudioProcessingQueue.Arn

functions:
  audioProcessor:
    handler: audio-processor/index.handler
    events:
      - sqs:
          arn: !GetAtt AudioProcessingQueue.Arn
          batchSize: 5

  geoTrigger:
    handler: geo-trigger/index.handler
    events:
      - sqs:
          arn: !GetAtt GeoTriggerQueue.Arn

resources:
  Resources:
    AudioProcessingQueue:
      Type: AWS::SQS::Queue
      Properties:
        QueueName: myapp-audio-processing-${self:provider.stage}
    GeoTriggerQueue:
      Type: AWS::SQS::Queue
      Properties:
        QueueName: myapp-geo-trigger-${self:provider.stage}

plugins:
  - serverless-esbuild
```

### 5.3 Stub Lambda handlers

Create `lambdas/audio-processor/index.js`:

```javascript
export const handler = async (event) => {
  console.log('audio-processor received', JSON.stringify(event))
  // TODO: implement audio processing
  return { statusCode: 200 }
}
```

Create `lambdas/geo-trigger/index.js`:

```javascript
export const handler = async (event) => {
  console.log('geo-trigger received', JSON.stringify(event))
  // TODO: implement geolocation trigger
  return { statusCode: 200 }
}
```

```bash
cd .. && git add . && git commit -m "scaffold lambdas"
```

---

## Phase 6 — Hotwire Native setup on Rails side

### 6.1 Install the bridge JS package

```bash
# If using importmap (the Rails 8 default):
bin/importmap pin @hotwired/hotwire-native-bridge

# If using a JS bundler (esbuild/bun):
npm install @hotwired/hotwire-native-bridge
```

### 6.2 Create bridge directory structure

```bash
mkdir -p app/javascript/controllers/bridge
mkdir -p config/hotwire_native
mkdir -p app/views/layouts
```

### 6.3 Path configuration

Create `config/hotwire_native/path_configuration.json`:

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": ["/auth/.*"],
      "properties": {
        "context": "modal"
      }
    },
    {
      "patterns": ["/player/.*"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": false
      }
    },
    {
      "patterns": [".*"],
      "properties": {
        "context": "default"
      }
    }
  ]
}
```

Serve it from a Rails route. In `config/routes.rb`:

```ruby
get "hotwire_native/path_configuration",
  to: proc { [200, { "Content-Type" => "application/json" },
    [File.read(Rails.root.join("config/hotwire_native/path_configuration.json"))]] }
```

### 6.4 Scaffold the AudioPlayer bridge component (JS side)

Create `app/javascript/controllers/bridge/audio_player_controller.js`:

```javascript
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "audio-player"

  connect() {
    super.connect()
    this.send("connect", {
      url: this.element.dataset.audioUrl,
      title: this.element.dataset.audioTitle
    }, () => {
      // native side called back — update UI if needed
    })
  }

  disconnect() {
    this.send("disconnect")
    super.disconnect()
  }
}
```

### 6.5 Scaffold the Location bridge component (JS side)

Create `app/javascript/controllers/bridge/location_controller.js`:

```javascript
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "location"

  connect() {
    super.connect()
    this.send("startTracking", {
      accuracy: "high",
      distanceFilter: 50   // metres between updates
    }, (data) => {
      // native sends back { latitude, longitude, heading }
      this.element.dispatchEvent(new CustomEvent("location:update", {
        detail: data, bubbles: true
      }))
    })
  }

  disconnect() {
    this.send("stopTracking")
    super.disconnect()
  }
}
```

### 6.6 Register bridge controllers

In `app/javascript/application.js` (or your Stimulus setup file):

```javascript
import { Application } from "@hotwired/stimulus"
import { BridgeComponent, BridgeElement } from "@hotwired/hotwire-native-bridge"

const application = Application.start()

// Register bridge components
import AudioPlayerController from "./controllers/bridge/audio_player_controller"
import LocationController from "./controllers/bridge/location_controller"

application.register("bridge--audio-player", AudioPlayerController)
application.register("bridge--location", LocationController)
```

```bash
git add . && git commit -m "add hotwire native bridge scaffolding on rails side"
```

---

## Phase 7 — Hotwire Native iOS project

> Requires Xcode 16+. Do this step on a Mac.

### 7.1 Create the Xcode project

```bash
mkdir -p mobile/ios
# Open Xcode → New Project → iOS → App
# Product Name: MyApp
# Team: your Apple Developer account
# Bundle Identifier: com.yourcompany.myapp
# Language: Swift
# Save to: mobile/ios/
```

### 7.2 Add Hotwire Native via Swift Package Manager

In Xcode → File → Add Package Dependencies:

```
https://github.com/hotwired/hotwire-native-ios
```

Select version `1.2.2` (or latest). Add `HotwireNative` to your app target.

### 7.3 Configure AppDelegate

Replace `AppDelegate.swift` with:

```swift
import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Hotwire.registerBridgeComponents([
            AudioPlayerComponent.self,
            LocationComponent.self
        ])
        return true
    }
}
```

### 7.4 Set the base URL

In your `SceneDelegate.swift` or initial view controller, set:

```swift
// Development
let baseURL = URL(string: "http://localhost:3000")!

// Production — read from a config plist or build setting
// let baseURL = URL(string: "https://yourdomain.com")!
```

### 7.5 Scaffold AudioPlayerComponent.swift

Create `mobile/ios/MyApp/Bridges/AudioPlayerComponent.swift`:

```swift
import AVFoundation
import HotwireNative
import UIKit

final class AudioPlayerComponent: BridgeComponent {
    override class var name: String { "audio-player" }

    private var player: AVPlayer?

    override func onReceive(message: Message) {
        switch message.event {
        case "connect":
            guard let url = message.jsonData["url"] as? String,
                  let audioURL = URL(string: url) else { return }
            setupPlayer(url: audioURL, title: message.jsonData["title"] as? String)
        case "disconnect":
            player?.pause()
            player = nil
        default:
            break
        }
    }

    private func setupPlayer(url: URL, title: String?) {
        // Configure AVAudioSession for background playback
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: []
        )
        try? AVAudioSession.sharedInstance().setActive(true)

        player = AVPlayer(url: url)
        player?.play()

        // Now Playing info for lock screen
        if let title {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: title
            ]
        }
    }
}
```

> **Important:** Add `UIBackgroundModes` → `audio` to `Info.plist` and enable
> the Background Modes capability in Xcode Signing & Capabilities.

### 7.6 Scaffold LocationComponent.swift

Create `mobile/ios/MyApp/Bridges/LocationComponent.swift`:

```swift
import CoreLocation
import HotwireNative

final class LocationComponent: BridgeComponent, CLLocationManagerDelegate {
    override class var name: String { "location" }

    private let locationManager = CLLocationManager()

    override func onReceive(message: Message) {
        switch message.event {
        case "startTracking":
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 50
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
        case "stopTracking":
            locationManager.stopUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        reply(to: "startTracking", with: [
            "latitude": loc.coordinate.latitude,
            "longitude": loc.coordinate.longitude,
            "heading": loc.course
        ])
    }
}
```

> **Important:** Add to `Info.plist`:
> - `NSLocationAlwaysAndWhenInUseUsageDescription`
> - `NSLocationWhenInUseUsageDescription`
>
> Enable Background Modes → Location updates in Xcode capabilities.

```bash
git add mobile/ios && git commit -m "scaffold hotwire native ios project"
```

---

## Phase 8 — Hotwire Native Android project

> Requires Android Studio Meerkat+. Do this step on a Mac or Linux.

### 8.1 Create the Android project

```bash
mkdir -p mobile/android
# Android Studio → New Project → Empty Activity
# Name: MyApp
# Package: com.yourcompany.myapp
# Language: Kotlin
# Min SDK: API 26 (Android 8.0)
# Save to: mobile/android/
```

### 8.2 Add Hotwire Native dependencies

In `mobile/android/app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("dev.hotwire:core:1.2.5")
    implementation("dev.hotwire:navigation-fragments:1.2.5")
    // ExoPlayer for audio
    implementation("androidx.media3:media3-exoplayer:1.3.0")
    implementation("androidx.media3:media3-ui:1.3.0")
    // Location
    implementation("com.google.android.gms:play-services-location:21.2.0")
}
```

In `settings.gradle.kts` add jitpack if using Masilotti's bridge component library:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
```

### 8.3 Register bridge components in Application class

Create `mobile/android/app/src/main/java/com/yourcompany/myapp/MyApp.kt`:

```kotlin
package com.yourcompany.myapp

import android.app.Application
import dev.hotwire.core.bridge.BridgeComponentFactory
import dev.hotwire.core.config.Hotwire

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("audio-player", ::AudioPlayerComponent),
            BridgeComponentFactory("location", ::LocationComponent)
        )
    }
}
```

Register in `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApp"
    ...>
```

### 8.4 Scaffold AudioPlayerComponent.kt

Create `mobile/android/app/src/main/java/com/yourcompany/myapp/AudioPlayerComponent.kt`:

```kotlin
package com.yourcompany.myapp

import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import org.json.JSONObject

class AudioPlayerComponent(
    name: String,
    private val delegate: BridgeDelegate<*>
) : BridgeComponent(name, delegate) {

    private var player: ExoPlayer? = null

    override fun onReceive(message: Message) {
        when (message.event) {
            "connect" -> {
                val data = JSONObject(message.jsonData ?: "{}")
                val url = data.optString("url")
                if (url.isNotBlank()) startPlayback(url)
            }
            "disconnect" -> {
                player?.stop()
                player?.release()
                player = null
            }
        }
    }

    private fun startPlayback(url: String) {
        val context = delegate.bridgeWebView?.context ?: return
        player = ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(url))
            prepare()
            play()
        }
    }
}
```

> **Important:** Add `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
> permissions to `AndroidManifest.xml`, and implement a `MediaSessionService`
> for lock screen controls.

### 8.5 Scaffold LocationComponent.kt

```kotlin
package com.yourcompany.myapp

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import org.json.JSONObject

class LocationComponent(
    name: String,
    private val delegate: BridgeDelegate<*>
) : BridgeComponent(name, delegate) {

    private var fusedClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null

    override fun onReceive(message: Message) {
        when (message.event) {
            "startTracking" -> startTracking()
            "stopTracking"  -> stopTracking()
        }
    }

    private fun startTracking() {
        val context = delegate.bridgeWebView?.context ?: return
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED) return

        fusedClient = LocationServices.getFusedLocationProviderClient(context)
        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000)
            .setMinUpdateDistanceMeters(50f)
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { loc ->
                    replyTo(message = Message("location", "startTracking",
                        JSONObject().apply {
                            put("latitude", loc.latitude)
                            put("longitude", loc.longitude)
                            put("heading", loc.bearing)
                        }.toString()
                    ))
                }
            }
        }
        fusedClient?.requestLocationUpdates(request, locationCallback!!, null)
    }

    private fun stopTracking() {
        locationCallback?.let { fusedClient?.removeLocationUpdates(it) }
    }
}
```

> **Important:** Add to `AndroidManifest.xml`:
> `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`,
> `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` permissions.

```bash
git add mobile/android && git commit -m "scaffold hotwire native android project"
```

---

## Phase 9 — CI for mobile builds

Create `.github/workflows/mobile.yml`:

```yaml
name: Mobile build

on:
  push:
    paths:
      - 'mobile/**'
      - 'config/hotwire_native/**'
      - 'app/javascript/controllers/bridge/**'

jobs:
  ios:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Build (no signing — check it compiles)
        run: |
          xcodebuild \
            -project mobile/ios/MyApp.xcodeproj \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -skipPackagePluginValidation \
            build | xcpretty

  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Build debug APK
        run: |
          cd mobile/android
          ./gradlew assembleDebug
```

---

## Phase 10 — Verification checklist

- [ ] `bin/dev` starts Rails locally on port 3000
- [ ] `docker compose up` starts Rails + Postgres + LocalStack
- [ ] `make setup` runs without errors (bundle + pnpm install + db:prepare)
- [ ] `make test` passes Rails specs and Lambda unit tests
- [ ] `make lint` passes ESLint across app/javascript and lambdas/
- [ ] `kamal setup` provisions the EC2 server (run once)
- [ ] `kamal deploy` deploys to production without errors
- [ ] `kamal deploy --destination staging` deploys to staging
- [ ] `aws secretsmanager get-secret-value --name myapp/production/RAILS_MASTER_KEY` returns the key (confirms IAM policy)
- [ ] iOS app compiles in Xcode simulator pointing at `http://localhost:3000`
- [ ] Android app compiles in emulator pointing at `http://10.0.2.2:3000` (emulator localhost alias)
- [ ] Path configuration JSON is reachable at `/hotwire_native/path_configuration`
- [ ] Audio bridge component plays audio in iOS simulator (foreground)
- [ ] GitHub Actions deploy workflow triggers on push to `main`
- [ ] GitHub Actions lambda workflow triggers only when `lambdas/` changes
- [ ] GitHub Actions mobile workflow triggers only when `mobile/` or `config/hotwire_native/` changes

---

## Known gotchas

**Solid Stack + PostgreSQL**: Using a single `DATABASE_URL` silently breaks the
Solid Queue, Cache, and Cable databases. Always use four separate URL env vars
as shown in Phase 1.4.

**iOS background audio**: AVAudioSession category must be `.playback` and the
`audio` background mode must be in `Info.plist`. Without this, audio stops when
the screen locks.

**iOS background location**: `allowsBackgroundLocationUpdates = true` alone is
not sufficient — you must also add the `location` background mode to
`Info.plist` and request `always` (not just `whenInUse`) authorisation.

**Android emulator localhost**: The Android emulator's `localhost` is the
emulator itself, not your Mac. Use `10.0.2.2` to reach your Mac's port 3000
during local development.

**Kamal secrets + GitHub Actions**: Kamal's `secrets fetch` command requires
the AWS CLI to be configured. In CI, use `aws-actions/configure-aws-credentials`
before running Kamal, not hardcoded env vars.

**Kamal first deploy vs subsequent deploys**: `kamal setup` only runs once. It
installs Docker on the server and runs the full boot sequence. After that,
`kamal deploy` handles all updates.