// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MiPrimerToken} from "../src/MiPrimerToken.sol";

contract DesplegarToken is Script {
    function run() external returns (MiPrimerToken) {
        // 1. Leemos la clave privada de las variables de entorno
        // (Para pruebas locales, Foundry puede usar una por defecto)
        uint256 privateKey = vm.envUint("PRIVATE_KEY");

        // 2. Todo lo que esté entre startBroadcast y stopBroadcast
        // se enviará como una transacción real a la red.
        vm.startBroadcast(privateKey);

        // Desplegamos el contrato
        MiPrimerToken token = new MiPrimerToken();

        vm.stopBroadcast();

        return token;
    }
}