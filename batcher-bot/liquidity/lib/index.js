#!/usr/bin/env node
"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var dotenv_1 = require("dotenv");
var bot_1 = require("./bot");
var settings_1 = require("./settings");
var signalr_1 = require("@microsoft/signalr");
var utils_1 = require("./utils");
var prelude_ts_1 = require("prelude-ts");
var chalk = require("chalk");
var clear = require("clear");
var figlet = require("figlet");
var Command = require("commander").Command;
var cli = new Command();
(0, dotenv_1.config)();
clear();
(0, utils_1.echo_terminal)("Batcher Bot", prelude_ts_1.Option.none());
var contract_address = process.env["BATCHER_ADDRESS"] || "No address defined";
var tzkt_api_uri = process.env["TZKT_URI_API"] || "No api defined";
var socket_connection = new signalr_1.HubConnectionBuilder()
    .withUrl(tzkt_api_uri + "/v1/ws")
    .build();
var preload = function () { return __awaiter(void 0, void 0, void 0, function () {
    var contract_uri;
    return __generator(this, function (_a) {
        contract_uri = "".concat(tzkt_api_uri, "/v1/contracts/").concat(contract_address, "/storage");
        console.info("contract_uri", contract_uri);
        return [2 /*return*/, fetch(contract_uri)
                .then(function (response) { return response.json(); })
                .then(function (json) {
                return (0, utils_1.get_contract_detail_from_storage)(contract_address, json);
            })];
    });
}); };
cli
    .name("batcher-liquidity-bot")
    .version("0.0.1")
    .description("Batcher Liquidity Bot CLI");
cli
    .command("jit")
    .description("Run Jit liquidity for Batcher")
    .argument("<string>", "Path to settings file")
    .action(function (p) {
    var sett = (0, settings_1.load_settings)(p);
    preload().then(function (contract_config) {
        (0, utils_1.echo_terminal)("Just-In-Time-Liquidity", prelude_ts_1.Option.of("Mnemonic"));
        (0, bot_1.run_jit)(contract_config, sett, socket_connection);
    });
});
cli
    .command("always-on")
    .description("Run always-on liquidity for Batcher")
    .argument("<string>", "Path to settings file")
    .action(function (p) {
    var sett = (0, settings_1.load_settings)(p);
    preload().then(function (contract_config) {
        (0, utils_1.echo_terminal)("Always-On-Liquidity", prelude_ts_1.Option.of("Mnemonic"));
        (0, bot_1.run_always_on)(contract_config, sett, socket_connection);
    });
});
cli.parse(process.argv);
if (!process.argv.slice(2).length) {
    cli.outputHelp();
}
