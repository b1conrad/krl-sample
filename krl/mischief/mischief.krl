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
                  "events": [ { "domain": "mischief", "type": "identify"} ] }
  }
  rule mischief_identify {
    select when mischief identify    event:send(
      { "eci": wrangler:parent().eci, "eid": "mischief-identify",
        "domain": "mischief", "type": "identify",
        "attrs": { "eci": wrangler:myself().eci } } )
  }
}
