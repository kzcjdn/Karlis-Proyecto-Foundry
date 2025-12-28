// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {MiPrimerToken} from "../src/MiPrimerToken.sol";

contract MiPrimerTokenTest is Test {
    MiPrimerToken public token;

    // Generamos direcciones legibles para los reportes de Foundry
    address public owner = makeAddr("Propietario");
    address public alice = makeAddr("Alice");
    address public bob = makeAddr("Bob");

    // Definimos el suministro inicial (1,000,000 tokens con 18 decimales)
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    function setUp() public {
        // El Propietario despliega el contrato
        vm.prank(owner);
        token = new MiPrimerToken();
    }

    // --- 1. VERIFICAR METADATOS Y DESPLIEGUE ---
    function test_Metadata() public {
        assertEq(token.name(), "Mi Primer Token");
        assertEq(token.symbol(), "MPT");
        assertEq(token.owner(), owner);
    }

    // --- 2. VERIFICAR SUMINISTRO INICIAL Y BALANCE DEL DEPLOYER ---
    function test_InitialSupplyAndBalance() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Suministro total incorrecto");
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY, "El Owner no recibio el suministro");
    }

    // --- 3. TRANSFERENCIA ENTRE CUENTAS ---
    function test_Transfer() public {
        uint256 amount = 100 ether;
        
        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    // --- 4. TRANSFERENCIA INVÁLIDA (Fallo por balance insuficiente) ---
    function test_TransferFailInsufficientBalance() public {
        uint256 tooMuch = INITIAL_SUPPLY + 1;

        vm.prank(owner);
        // Las versiones nuevas de OpenZeppelin usan este error personalizado:
        vm.expectRevert(); 
        token.transfer(alice, tooMuch);
    }

    // --- 5. FLUJO COMPLETO: APPROVE Y TRANSFERFROM ---
    function test_ApproveAndTransferFrom() public {
        uint256 amount = 500 ether;

        // Owner aprueba a Alice para que gaste sus tokens
        vm.prank(owner);
        token.approve(alice, amount);

        assertEq(token.allowance(owner, alice), amount);

        // Alice (el spender) mueve tokens de Owner a Bob
        vm.prank(alice);
        token.transferFrom(owner, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.allowance(owner, alice), 0);
    }

    // --- 6. ACCESO: SOLO EL OWNER PUEDE MINTEAR ---
    function test_OwnerCanMint() public {
        uint256 mintAmount = 1000 ether;
        
        vm.prank(owner);
        token.mint(alice, mintAmount);
        
        assertEq(token.balanceOf(alice), mintAmount);
    }

    function test_NonOwnerCannotMint() public {
        uint256 mintAmount = 1000 ether;

        // Esperamos el error de acceso de OpenZeppelin
        // abi.encodeWithSignature permite capturar errores que llevan parámetros
        vm.expectRevert(
            abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice)
        );

        vm.prank(alice);
        token.mint(alice, mintAmount);
    }

    // --- 7. FUZZING DE TRANSFERENCIAS ---
    function testFuzz_Transfer(uint256 amount) public {
        // Filtramos para que Foundry solo use valores válidos (entre 0 y el supply)
        vm.assume(amount <= INITIAL_SUPPLY);

        vm.prank(owner);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }
}