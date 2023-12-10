* 27 test
  * 212 - recovery_duration 
* 28 test
  * 214 - recovery_duration
* 30 test
  * 406 - recovery_duration
* 31 test
  * 417 - recovery_duration
* 32 test
  * 423 - recovery_duration
* 33 test
  * 135 - recovery_duration
* 36 test
  * 277 - recovery_duration
* 37 test
  * 614 - recovery_duration
* 38 test
  * 764 - recovery_duration 

# control-plane recovery durations
* 39 test
  * 964 - recovery_duration
* 40 test
  * 963 - recovery_duration
* 41 test
  * 963 - recovery_duration
* 42 test
  * 963 - recovery_duration

# worker recovery durations (waiting 100 sec was unnecessary, TODO: subtract them in final calc)
* 47 test (node_1)
  * 957 - recovery_duration
* 48 test (node_1)
  * 1057 - recovery_duration
* 49 test (node_2)
  * 1058
* 50 test (node_2)
  * 1058
* 51 test (node_2)
  * 1058
* 52 test (node_1)
  * 1058
* 53 test (node_3)
  * 1059
* 54 test (node_3)
  * 1060
* 54 test (node_3)
  * 1059


# worker recovery duration long run (no pressure)
* 56 (node_1)
  * "recovery_duration": "1230"
* 57 (node_1)
  * "recovery_duration": "1006"
* 58 (node_1)
  * "recovery_duration": "1120"
* 59 (node_2)
  * "recovery_duration": "1006"
* 60 (node_2)
  * "recovery_duration": "1006"
* 61 (node_2)
  * "recovery_duration": "1006"
* 62 (node_3) - after it no pods on that node anymore
  * "recovery_duration": "1006"

# control recovery duration long run (no pressure)
* 63 (master) failed one!
  * "recovery_duration": "1005"


* 64 (master) 
  * "recovery_duration": "1009"
* 65 (master) 
  * "recovery_duration": "1009"
* 66 (master) 
  * "recovery_duration": "1009"