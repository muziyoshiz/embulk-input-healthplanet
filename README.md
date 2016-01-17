# Healthplanet input plugin for Embulk

Retrieve your data from [TANITA's Health Planet website](https://www.healthplanet.jp/) through Health Planet API v1.

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
- **lang**: Language for column name (string, default: en)
    - en or english: English name such as "weight" or "body fat %"
    - ja or japanese: Japanese name such as "体重" or "体脂肪率"
    - other: as-is API tag such as "6021" or "6022"

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

Health Planet API ver. 1.0 does not export 'Body Water Mass' data. I reported this issue to TANITA. But with no word of thanks, they just replied that they did not fix this issue because this API was free. embulk-input-healthplanet therefore can not export the 'Body Water Mass' data, too.

## References

* [Health Planet API Specification Ver. 1.0 (Japanese)](http://www.healthplanet.jp/apis/api.html)
* [Health Planet からデータをエクスポートするための embulk-input-healthplanet プラグイン - 無印吉澤](http://muziyoshiz.hatenablog.com/entry/2016/01/11/234921 "Health Planet からデータをエクスポートするための embulk-input-healthplanet プラグイン - 無印吉澤")
