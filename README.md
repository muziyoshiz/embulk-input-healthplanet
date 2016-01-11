# Healthplanet input plugin for Embulk

Retrieve your innerscan data through Health Planet API v1.

This plugin only supports 'innerscan' scope. Other scopes such as 'sphygmomanometer', 'pedometer' and 'smug' are not supported.

## Overview

* **Plugin type**: input
* **Resume supported**: no
* **Cleanup supported**: no
* **Guess supported**: no

## Configuration

- **login_id**: Login ID for Health Planet website (string, required)
- **password**: Password for Health Planet website (string, required)
- **client_id**: Client ID for your client application using this plugin (string, required)
- **client_secret**: Client Secret for your client application using this plugin (string, required)

## Example

```yaml
in:
  type: healthplanet
  login_id: example_login_id
  password: example_password
  client_id: example.apps.healthplanet.jp
  client_secret: 12345678901123-ExampleClientSecret
```

## Build

```
$ rake
```

## References

* [Health Planet API Specification Ver. 1.0 (Japanese)](http://www.healthplanet.jp/apis/api.html)
