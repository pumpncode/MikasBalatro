-- Credits
SMODS.current_mod.extra_tabs = function()
    return {
        label = "Credits",
        tab_definition_function = function()
            return {
                -- TODO: Credit Grassy for art, Elbe and Dimserene for porting and maintaining.
            }
        end
    }
end

---Localization
G.localization.descriptions.Other.mikas_card_extra_mult = { text = { "{C:mult}+#1#{} extra Mult" } }
G.localization.misc.dictionary.k_mikas_charging = "Charging..."
G.localization.misc.dictionary.k_mikas_bonus = "Bonus!"
G.localization.misc.dictionary.k_mikas_hand_up = "+ Hand Size!"
G.localization.misc.dictionary.k_mikas_hand_down = "- Hand Size!"
G.localization.misc.dictionary.k_mikas_tick = "Tick..."
G.localization.misc.dictionary.k_mikas_plus_card = "Card!"
G.localization.misc.dictionary.k_mikas_luck = "+ Luck!"
G.localization.misc.dictionary.k_mikas_destroy = "Destroy!"

init_localization()

-- Atlas
SMODS.Atlas {
    key = "mikas_jokers",
    path = "Jokers.png",
    px = 71,
    py = 95
}

SMODS.Atlas {
    key = "mikas_tarots",
    path = "Tarots.png",
    px = 71,
    py = 95
}

SMODS.Atlas {
    key = "mikas_spectrals",
    path = "Spectrals.png",
    px = 71,
    py = 95
}

SMODS.Atlas {
    key = "mikas_decks",
    path = "Decks.png",
    px = 71,
    py = 95
}

-- Jokers
SMODS.Joker {
    key = "prime_time",
    loc_txt = {
        name = "Prime Time",
        text = {
            "Each played {C:attention}2{},",
            "{C:attention}3{}, {C:attention}5{}, {C:attention}7{} or {C:attention}Ace{}, gives",
            "{X:mult,C:white}X#1#{} Mult when scored"
        }
    },

    config = {
        extra = {
            Xmult = 1.2
        }
    },
    rarity = 1,
    cost = 4,

    atlas = "mikas_jokers",
    pos = { x = 0, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult } }
    end,

    calculate = function(self, card, context)
        -- For each played card, if card is prime, add xmult
        if context.individual and context.cardarea == G.play and
            (context.other_card:get_id() == 2 or context.other_card:get_id() == 3 or context.other_card:get_id() ==
                5 or context.other_card:get_id() == 7 or context.other_card:get_id() == 14) then
            return {
                message = localize {
                    type = "variable",
                    key = "a_xmult",
                    vars = { card.ability.extra.Xmult }
                },
                x_mult = card.ability.extra.Xmult,
                card = card
            }
        end
    end
}

SMODS.Joker {
    key = "straight_nate",
    loc_txt = {
        name = "Straight Nate",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played hand",
            "contains a {C:attention}Straight{} and you have",
            "both {C:attention}Odd Todd{} and {C:attention}Even Steven{}",
            "Gives {C:dark_edition}+#2#{} Joker slot"
        }
    },

    config = {
        extra = {
            Xmult = 4,
            j_slots = 1
        }
    },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 1, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.j_slots } }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            -- If hand played is a straight
            if next(context.poker_hands["Straight"]) then
                -- Check for Odd Todd, Straight Nate, or Dynamic Duo (Merged)
                if (next(find_joker("Odd Todd")) and next(find_joker("Even Steven"))) or next(find_joker("Dynamic Duo")) then
                    -- Add xmult
                    return {
                        message = localize {
                            type = "variable",
                            key = "a_xmult",
                            vars = { card.ability.extra.Xmult }
                        },
                        Xmult_mod = card.ability.extra.Xmult
                    }
                end
            end
        end
    end,

    -- Add Joker slot when added to deck
    add_to_deck = function(self, card, from_debuff)
        G.jokers.config.card_limit = G.jokers.config.card_limit + card.ability.extra.j_slots
    end,

    -- Remove Joker slot when removed to deck
    remove_from_deck = function(self, card, from_debuff)
        G.jokers.config.card_limit = G.jokers.config.card_limit - card.ability.extra.j_slots
    end,

    -- Become available once the player has Odd Todd, Even Steven or Dynamic Duo
    in_pool = function(self)
        if next(find_joker("Odd Todd")) or next(find_joker("Even Steven")) or next(find_joker("Dynamic Duo")) then
            return true
        end
        return false
    end
}

SMODS.Joker {
    key = "fisherman",
    loc_txt = {
        name = "The Fisherman",
        text = {
            "{C:attention}+#2#{} hand size per discard",
            "{C:attention}-#2#{} hand size per hand played",
            "Resets every round",
            "{C:inactive}(Currently {C:attention}#3##1#{C:inactive} hand size)"
        }
    },

    config = {
        extra = {
            current_h_size = 0,
            h_mod = 1
        }
    },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 2, y = 0 },

    loc_vars = function(self, info_queue, card)
        local modifier = ""
        if card.ability.extra.current_h_size >= 0 then
            modifier = "+"
        end
        return { vars = { card.ability.extra.current_h_size, card.ability.extra.h_mod, modifier } }
    end,

    calculate = function(self, card, context)
        -- Decrease hand size
        if context.joker_main then
            card.ability.extra.current_h_size = card.ability.extra.current_h_size - card.ability.extra.h_mod
            G.hand:change_size(-card.ability.extra.h_mod)
            -- Decrease message
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = localize("k_mikas_hand_down")
            })
        end

        -- Increase hand size
        if context.pre_discard then
            card.ability.extra.current_h_size = card.ability.extra.current_h_size + card.ability.extra.h_mod
            G.hand:change_size(card.ability.extra.h_mod)
            -- Increase message
            card_eval_status_text(card, "extra", nil, nil, nil, {
                message = localize("k_mikas_hand_up")
            })
        end

        -- Reset hand size
        if context.end_of_round and not context.individual and not context.repetition then
            if card.ability.extra.current_h_size ~= 0 then
                G.hand:change_size(-card.ability.extra.current_h_size)
                card.ability.extra.current_h_size = 0
                -- Reset message
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = localize("k_reset")
                })
            end
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        -- Reset hand size
        if card.ability.extra.current_h_size ~= 0 then
            G.hand:change_size(-card.ability.extra.current_h_size)
            card.ability.extra.current_h_size = 0
        end
    end
}

SMODS.Joker {
    key = "impatient",
    loc_txt = {
        name = "Impatient Joker",
        text = {
            "{C:mult}+#2#{} Mult per card discarded",
            "Resets every round",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)"
        }
    },

    config = {
        extra = {
            mult_mod = 3,
            current_mult = 0
        }
    },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 3, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.current_mult, card.ability.extra.mult_mod } }
    end,

    calculate = function(self, card, context)
        -- Apply mult
        if context.joker_main then
            if card.ability.extra.current_mult > 0 then
                return {
                    message = localize {
                        type = "variable",
                        key = "a_mult",
                        vars = { card.ability.extra.current_mult }
                    },
                    mult_mod = card.ability.extra.current_mult,
                    card = card
                }
            end
        end

        -- Increase mult for each discarded card
        if context.discard and not context.blueprint then
            card.ability.extra.current_mult = card.ability.extra.current_mult + card.ability.extra.mult_mod
            return {
                message = localize {
                    type = "variable",
                    key = "a_mult",
                    vars = { card.ability.extra.mult_mod }
                },
                colour = G.C.RED,
                card = card
            }
        end

        -- Reset mult
        if context.end_of_round and not context.individual and not context.repetition and not context.blueprint then
            if card.ability.extra.current_mult ~= 0 then
                card.ability.extra.current_mult = 0
                -- Reset message
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = localize("k_reset")
                })
            end
        end
    end
}

SMODS.Joker {
    key = "cultist",
    loc_txt = {
        name = "Cultist",
        text = {
            "{X:mult,C:white}X#2#{} Mult per hand played",
            "Resets every round",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)"
        }
    },

    config = {
        extra = {
            current_Xmult = 1,
            Xmult_mod = 1,
            old = 0
        }
    },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 4, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.current_Xmult, card.ability.extra.Xmult_mod } }
    end,

    calculate = function(self, card, context)
        -- Increment Xmult
        if context.before and not context.blueprint then
            card.ability.extra.old = card.ability.extra.current_Xmult
            card.ability.extra.current_Xmult = card.ability.extra.current_Xmult + card.ability.extra.Xmult_mod
        end

        -- Apply xmult
        if context.joker_main then
            if card.ability.extra.old > 1 then
                return {
                    message = localize {
                        type = "variable",
                        key = "a_xmult",
                        vars = { card.ability.extra.old }
                    },
                    Xmult_mod = card.ability.extra.old,
                    card = card
                }
            end
        end

        -- Reset mult
        if context.end_of_round and not context.individual and not context.repetition and not context.blueprint then
            if card.ability.extra.current_Xmult ~= 1 then
                card.ability.extra.current_Xmult = 1
                -- Reset message
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = localize("k_reset")
                })
            end
        end
    end
}

SMODS.Joker {
    key = "seal_collector",
    loc_txt = {
        name = "Seal Collector",
        text = {
            "Gains {C:chips}+#2#{} Chips for",
            "every card with a {C:attention}seal",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        }
    },

    config = {
        extra = {
            current_chips = 0,
            chip_mod = 25,
            seal_count = 0
        }
    },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 5, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.current_chips, card.ability.extra.chip_mod } }
    end,

    calculate = function(self, card, context)
        -- Apply chips
        if context.joker_main then
            return {
                message = localize {
                    type = "variable",
                    key = "a_chips",
                    vars = { card.ability.extra.current_chips }
                },
                chip_mod = card.ability.extra.current_chips,
                card = card
            }
        end
    end,

    update = function(self, card)
        if G.playing_cards then
            local seals = 0
            -- Count all seal cards
            for _, v in pairs(G.playing_cards) do
                if v.seal ~= nil then
                    seals = seals + 1
                end
            end

            -- Check for change in seals
            if card.ability.extra.seal_count ~= seals then
                -- Change chip amount
                card.ability.extra.current_chips = seals * card.ability.extra.chip_mod
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.0,
                    func = (function()
                        if card.added_to_deck then
                            card_eval_status_text(card, "extra", nil, nil, nil, {
                                message = localize {
                                    type = "variable",
                                    key = "a_chips",
                                    vars = { card.ability.extra.current_chips }
                                },
                                colour = G.C.CHIPS
                            })
                        end
                        return true
                    end)
                }))
                -- Update seal count
                card.ability.extra.seal_count = seals
            end
        end
    end
}

SMODS.Joker {
    key = "camper",
    loc_txt = {
        name = "Camper",
        text = {
            "Every discarded {C:attention}card{}",
            "permanently gains",
            "{C:chips}+#1#{} Chips"
        }
    },

    config = {
        extra = {
            chip_mod = 4
        }
    },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 6, y = 0 },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod } }
    end,

    calculate = function(self, card, context)
        -- If discarded
        if context.discard then
            -- Add chips to card
            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus or 0
            context.other_card.ability.perma_bonus = context.other_card.ability.perma_bonus +
                card.ability.extra.chip_mod
            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.CHIPS,
                card = card
            }
        end
    end
}

SMODS.Joker {
    key = "scratch_card",
    loc_txt = {
        name = "Scratch Card",
        text = {
            "Gain {C:money}$#1#{}, {C:money}$#2#{}, {C:money}$#3#{}, {C:money}$#4#{},",
            "{C:money}$#5#{} when 1, 2, 3, 4 or 5",
            "{C:attention}7 cards{} are scored,",
            "respectively"
        }
    },

    config = {
        extra = {
            base = 1,
            dollars = 0,
            seven_tally = 0
        }
    },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = false,
    blueprint_compat = true,

    atlas = "mikas_jokers",
    pos = { x = 7, y = 0 },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.base,
                card.ability.extra.base * 3,
                card.ability.extra.base * 10,
                card.ability.extra.base * 25,
                card.ability.extra.base * 50
            }
        }
    end,

    calculate = function(self, card, context)
        -- Count sevens
        if context.individual and context.cardarea == G.play and context.other_card:get_id() == 7 and
            not context.blueprint then
            card.ability.extra.seven_tally = card.ability.extra.seven_tally + 1
        end

        if context.joker_main then
            -- Set dollars depending on amount of 7s
            if card.ability.extra.seven_tally == 1 then
                card.ability.extra.dollars = card.ability.extra.base
            elseif card.ability.extra.seven_tally == 2 then
                card.ability.extra.dollars = card.ability.extra.base * 3
            elseif card.ability.extra.seven_tally == 3 then
                card.ability.extra.dollars = card.ability.extra.base * 10
            elseif card.ability.extra.seven_tally == 4 then
                card.ability.extra.dollars = card.ability.extra.base * 25
            elseif card.ability.extra.seven_tally >= 5 then
                card.ability.extra.dollars = card.ability.extra.base * 50
            end

            -- Give money
            if card.ability.extra.seven_tally >= 1 then
                ease_dollars(card.ability.extra.dollars)
                return {
                    message = localize("$") .. card.ability.extra.dollars,
                    dollars = card.ability.extra.dollars,
                    colour = G.C.MONEY
                }
            end
        end

        -- Reset
        if context.after and not context.blueprint and context.cardarea == G.jokers then
            card.ability.extra.dollars = 0
            card.ability.extra.seven_tally = 0
        end
    end
}
