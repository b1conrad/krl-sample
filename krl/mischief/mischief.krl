ruleset mischief {
  meta {
    name "mischief"
    description <<
      A bit of whimsy,
      inspired by Dr. Seuss's
      "The Cat in the Hat"
    >>
    author "Picolabs"
    use module io.picolabs.pico alias wrangler
    use module Subscriptions
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "mischief", "type": "identity"},
                              { "domain": "mischief", "type": "hat_lifted"} ] }
  }
  rule mischief_identity {
    select when mischief identity
    event:send(
      { "eci": wrangler:parent().eci, "eid": "mischief-identity",
        "domain": "mischief", "type": "who",
        "attrs": { "eci": wrangler:myself().eci } } )
  }
  rule mischief_hat_lifted {
    select when mischief hat_lifted
    foreach Subscriptions:getSubscriptions() setting (subscription)
      pre {
        thing_subs = subscription.klog("subs")
        subs_attrs = thing_subs{"attributes"}
      }
      if subs_attrs{"subscriber_role"} == "thing" then
        send_directive("hat lifted") with eci = subs_attrs{"outbound_eci"}
        event:send(
          { "eci": subs_attrs{"outbound_eci"}, "eid": "hat-lifted",
            "domain": "mischief", "type": "hat_lifted" }
        )
  }
}
