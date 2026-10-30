local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"
local selectors = require "modules.state.selectors"

local M = {}

local OPTIONS = {
	{ label = "Deposit", value = "Deposit" },
	{ label = "Withdraw", value = "Withdraw" },
	{ label = "Borrow", value = "Borrow" },
	{ label = "Repay", value = "Repay" },
}

local function savings_message(savings)
	return "Now you have " .. savings .. " gold pieces in your savings account."
end

function M.create()
	local b = use_building(true)
	local deposit_amount = 0
	local withdraw_amount = 0
	local borrow_amount = 0

	local building = {}

	function building.view()
		local option, step = b.option, b.step
		local vendor = { body = "Welcome to our regional branch of the Marco Polo Bank." }
		local children

		local menu = function(x, y)
			widgets.building_menu("menu", x, y, OPTIONS, {
				hidden = option ~= nil or step == -1,
				on_select = b.select_option,
				on_cancel = function()
					b.back()
				end,
			})
		end

		if option == "Deposit" then
			local gold = selectors.get_gold()
			local savings = selectors.get_savings()

			if step == 0 then
				if gold == 0 then
					vendor = { body = "You don’t have any gold to deposit.", acknowledge = b.reset }
				elseif savings == 0 then
					vendor = { body = "You don’t have any gold in your account.", acknowledge = b.next }
				else
					vendor = { body = savings_message(savings), acknowledge = b.next }
				end
			elseif step == 1 then
				vendor = { body = "How much would you like to deposit? (0-" .. gold .. ")" }
				children = function()
					widgets.input_number("deposit", gold, function(amount)
						actions_port.deposit(amount)
						deposit_amount = amount
						b.next()
					end, b.reset)
				end
			elseif step == 2 then
				vendor = {
					body = "We’ll deposit " .. deposit_amount .. " gold pieces into your account. The monthly interest rate is 3%",
					acknowledge = b.next,
				}
			elseif step == 3 then
				vendor = { body = savings_message(savings), acknowledge = b.reset }
			end
		end

		if option == "Withdraw" then
			local savings = selectors.get_savings()

			if step == 0 then
				if savings == 0 then
					vendor = { body = "You don’t have any gold in your account.", acknowledge = b.reset }
				else
					vendor = { body = savings_message(savings), acknowledge = b.next }
				end
			elseif step == 1 then
				vendor = { body = "How much would you like to withdraw? (0-" .. savings .. ")" }
				children = function()
					widgets.input_number("withdraw", savings, function(amount)
						actions_port.withdraw(amount)
						withdraw_amount = amount
						b.next()
					end, b.reset)
				end
			elseif step == 2 then
				vendor = { body = "Here is " .. withdraw_amount .. " gold from your account.", acknowledge = b.next }
			elseif step == 3 then
				vendor = { body = savings_message(savings), acknowledge = b.reset }
			end
		end

		if option == "Borrow" then
			local credit_line = selectors.get_credit_line()

			if step == 0 then
				if credit_line > 0 then
					vendor = { body = "Your credit line is " .. credit_line .. " gold pieces.", acknowledge = b.next }
				else
					vendor = {
						body = "With your poor credit history, there’s no way we can give you a loan.",
						acknowledge = b.reset,
					}
				end
			elseif step == 1 then
				vendor = { body = "How much gold do you need to borrow? (0-" .. credit_line .. ")" }
				children = function()
					widgets.input_number("borrow", credit_line, function(amount)
						actions_port.borrow(amount)
						borrow_amount = amount
						b.next()
					end, b.reset)
				end
			elseif step == 2 then
				vendor = { body = "Then we’ll lend you " .. borrow_amount .. " gold pieces.", acknowledge = b.next }
			elseif step == 3 then
				vendor = {
					body = "The monthly interest rate is 10%. Please invest our loan wisely.",
					acknowledge = b.reset,
				}
			end
		end

		if option == "Repay" then
			local debt = selectors.get_debt()

			if step == 0 then
				if debt == 0 then
					vendor = { body = "You don’t owe us any money.", acknowledge = b.reset }
				else
					vendor = { body = "Now your debt is " .. debt .. " gold.", acknowledge = b.next }
				end
			elseif step == 1 then
				local repay_amount = selectors.get_repay_amount()
				if repay_amount == 0 then
					-- this condition is not handled in the original game, and you get (0-0)
					vendor = { body = "You don’t have any gold to pay back your loan with.", acknowledge = b.reset }
				else
					vendor = { body = "How much of your loan will you be paying back? (0-" .. repay_amount .. ")" }
					children = function()
						widgets.input_number("repay", repay_amount, function(amount)
							actions_port.repay(amount)
							b.next()
						end, b.reset)
					end
				end
			elseif step == 2 then
				vendor = { body = "Thank you for your payment.", acknowledge = b.next }
			elseif step == 3 then
				if debt == 0 then
					vendor = {
						body = "Well, that takes care of your debt! Thank you for using Marco Polo Bank.",
						acknowledge = b.reset,
					}
				else
					vendor = { body = "Now your debt is " .. debt .. " gold.", acknowledge = b.next }
				end
			elseif step == 4 then
				vendor = {
					body = "The monthly interest rate is 10%. Please invest our loan wisely.",
					acknowledge = b.reset,
				}
			end
		end

		if step == -1 then
			vendor = {
				body = "Thank you for choosing Marco Polo Bank.",
				acknowledge = function()
					b.back()
				end,
			}
		end

		return {
			building_id = "9",
			vendor = vendor,
			menu = menu,
			children = children,
		}
	end

	return building
end

return M
