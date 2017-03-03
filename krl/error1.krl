ruleset error1 {
  meta {
    shares __testing
  }
  global {
    __testing = { "events": [ { "domain": "trigger", "type": "error" } ] }
  }

  rule trigger_error {
    select when trigger error
    send_directive("error")
      with trigger = myFunction()
  }
}
