-- fixture: poisoned — a stray layer rule names the fixture surface
hl.layer_rule({ match = { namespace = "totallyunrelated" }, blur = true })
hl.layer_rule({ match = { namespace = "retirement-fixture" }, blur = true })
