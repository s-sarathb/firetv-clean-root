# Fire OS 7 Package Classification & Debloat Reference

## Package Categories

### 1. Telemetry, Analytics & Metrics (Safe to disable with Root)
| Package | Description | Reason to Disable |
|---|---|---|
| `com.amazon.client.metrics` | Core metrics client | Transmits usage events to Amazon |
| `com.amazon.client.metrics.api` | Metrics API broker | Background logging worker |
| `com.amazon.device.metrics` | Device metrics daemon | Battery/CPU tracking |
| `com.amazon.device.logmanager` | System log manager | Gathers logcat data |
| `com.amazon.device.crashmanager` | Crash report uploader | Sends diagnostic dumps |
| `com.amazon.dp.logger` | Diagnostic logger | Continuous log processing |
| `com.amazon.diode` | Diagnostic uploader | On-device data collector |
| `com.amazon.ceviche` | Data telemetry pipeline | Usage telemetry sync |
| `com.fireos.usagestats.proxy` | App usage stats proxy | Reports app open/close duration |
| `com.amazon.wifilocker` | Wi-Fi credential sync | Uploads passwords to Amazon cloud |

### 2. Ads, Recommendations & Shopping (Safe to disable)
| Package | Description | Reason to Disable |
|---|---|---|
| `com.amazon.kso.blackbird` | Ad synchronization service | Pulls sponsored banners |
| `com.amazon.sneakpeek` | Sponsored preview player | Plays video ads in background |
| `com.amazon.ftvads.deeplinking` | Ad deep link resolver | Handles ad click routing |
| `com.amazon.hybridadidservice` | Advertising ID daemon | Tracks personalized ad profiles |
| `com.amazon.hedwig` | Fire TV Channels | Ad-supported streaming content rows |
| `com.amazon.shoptv.client` | Amazon Live Shopping | Shopping on TV UI |
| `com.amazon.shoptv.firetv.client` | Shopping client | Live video shopping service |
| `com.amazon.gamehub` | Luna Gaming Hub | Luna recommendation cards |

### 3. Preloaded Bloatware (Safe to disable / uninstall)
| Package | Description | Reason to Disable |
|---|---|---|
| `com.amazon.tahoe` | Amazon Kids (FreeTime) | Child profile enforcement |
| `com.amazon.bueller.music` | Amazon Music | Preloaded music app |
| `com.amazon.dummy.music` | Music stub | Music placeholder |
| `com.amazon.bueller.photos` | Amazon Photos | Cloud photo backup service |
| `com.amazon.cloud9` | Silk Browser | Web browser with Amazon search telemetry |
| `com.amazon.tv.website_launcher` | Silk link launcher | Opens URLs in Silk |

### 4. CRITICAL: Load-Bearing Packages (DO NOT DISABLE)
| Package | Component | Consequence if Disabled |
|---|---|---|
| `com.amazon.tv.settings.v2` | Fire TV Settings | Lose access to Network, Display, Remote pairing |
| `com.amazon.tv.ime` | On-screen Keyboard | Virtual keyboard disappears; cannot enter text |
| `android` / `com.android.providers.settings` | Android OS Settings | Bootloop / System Server crash |
| `com.amazon.device.bluetooth` | Bluetooth stack | Remote control loses connection permanently |
| `in.startv.hotstar` | JioHotstar | Video playback and user account data |
