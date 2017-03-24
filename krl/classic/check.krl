ruleset check {
  rule check {
    select when check check
    pre {
      check = event:attr("check");
      test = { [check,"mark"]: 42 };
    }
    send_directive("check") with check = test and alpha = "omega";
    always {
      set ent:check{[check]} check;
    }
  }
}
