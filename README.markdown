# isamroathisdesk

I hacked together a little iOS app for http://isamroathisdesk.heroku.com. I've done a few things wrong here, like auth, which basically involves a secret passed from the client. That said, it's a decent proof of concept.

(A Rails app)[http://github.com/amro/isamroathisdesk-rails] stores status updates and displays the latest available status. This iOS app handles updating status when a given iBeacon is detected. Leaving the beacon range works great. After 30 seconds or so, the status changes to unavailable. Entering beacon range works great if the app is in the foreground. If it's in the background, it could take up to 15-20 minutes before iOS wakes the app up to let it know it's entered the beacon range. `locationManager:didEnterRegion:` seems to be called when the device's radios wake up. This makes a lot of sense from a power-saving perspective. Also, it doesn't seem that iOS calls `locationManager:didRangeBeacons:inRegion:` when the app is in the background.

That's all there is to it.