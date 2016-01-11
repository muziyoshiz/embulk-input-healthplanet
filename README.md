# Healthplanet input plugin for Embulk

Retrieve your innerscan data through Health Planet API v1.

This plugin only supports 'innerscan' scope. Other scopes such as 'sphygmomanometer', 'pedometer' and 'smug' are not supported.

## Overview

* **Plugin type**: input
* **Resume supported**: no
* **Cleanup supported**: no
* **Guess supported**: no

## Install

```
$ embulk gem install embulk-input-healthplanet
```

## Configuration

- **login_id**: Login ID for Health Planet website (string, required)
- **password**: Password for Health Planet website (string, required)
- **client_id**: Client ID for your client application using this plugin (string, required)
- **client_secret**: Client Secret for your client application using this plugin (string, required)
- **next_from**: Retrieve data from the time '%Y-%m-%d %H:%M:%S' (string, default: 1 year ago)

## Example

```yaml
in:
  type: healthplanet
  login_id: example_login_id
  password: example_password
  client_id: example.apps.healthplanet.jp
  client_secret: 12345678901123-ExampleClientSecret
  next_from: '2015-01-01 00:00:00'
exec: {}
out:
  type: file
  path_prefix: ./healthplanet/
  file_ext: csv
  formatter:
    type: csv
    default_timezone: 'Asia/Tokyo'
```

If only new records are required, please use -o option as follows:

```
$ embulk run config.yml -o config.yml
```

## Notice

Health Planet API ver. 1.0 can not export 'Body Water Mass' data. Therefore embulk-input-healthplanet can not export the data, too.

## References

* [Health Planet API Specification Ver. 1.0 (Japanese)](http://www.healthplanet.jp/apis/api.html)
