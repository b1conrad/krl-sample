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
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "mischief", "type": "identity"} ] }
  }
  rule mischief_identity {
    select when mischief identity
    event:send(
      { "eci": wrangler:parent().eci, "eid": "mischief-identity",
        "domain": "mischief", "type": "who",
        "attrs": { "eci": wrangler:myself().eci } } )
  }
}
