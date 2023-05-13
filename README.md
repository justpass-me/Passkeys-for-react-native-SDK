# react native package for justpass.me

## Installation

```sh
yarn add @justpass-me/justpass-me-react-native
cd ios
pod install
```

## Setup
- Open justpass.me dashboard and update the apple app package to be `{your-app-domain}.accounts.justpass.me`
- Make sure to add `webcredentials:{your-app-domain}.accounts.justpass.me` to your app [associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains#Add-the-associated-domains-entitlement-to-your-app)

## Usage

```typescript
import {register, authenticate} from '@justpass-me/justpass-me-react-native'

const firebaseProjectName = "my-firebase-project" // the firebase project where the extension is installed
const cloudLocation = "us-central1" // location where the extension is installed
const extensionInstanceName = "ext-justpass-me"
const baseURL = `https://${cloudLocation}-${firebaseProjectName}.cloudfunctions.net/${extensionInstanceName}-oidc`

// registration
const registrationURL = `${baseURL}/register/`
const IdToken = await auth().currentUser.getIdToken()
const extraHeaders = {
    Authorization: `Bearer ${IdToken}`
}
await register(registrationURL, extraHeaders)

// login
const authenticationURL = `${baseURL}/authenticate/`
const result = await authenticate(authenticationURL)
if (result.token) {
    await auth().signInWithCustomToken(result.token)
}`
```
