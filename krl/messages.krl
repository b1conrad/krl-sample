ruleset messages {
  meta {
    shares __testing, seeAllMessages
  }
  global {
    __testing = { "queries": [ { "name": "__testing" }, { "name": "seeAllMessages" } ],
                  "events": [ { "domain": "messages", "type": "new_message",
                                "attrs": [ "text" ] } ] }
    seeAllMessages = function() {
      ent:messages
    }
  }

  rule messages_new_message {
    select when messages new_message
    fired {
      ent:messages := ent:messages.defaultsTo([]).append([event:attr("text")])
    }
  }
}
