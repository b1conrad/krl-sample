ruleset mischief.thing {
  meta {
    name "mischief.thing"
    description <<
      A bit of whimsy,
      inspired by Dr. Seuss's
      "The Cat in the Hat"
    >>
    author "Picolabs"
    use module io.picolabs.pico alias wrangler
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ] }
  }
  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs().klog("subcription:")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
}
