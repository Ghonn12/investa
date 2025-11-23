<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// CORS Preflight (Agar Flutter bisa akses jika debug di Web)
$routes->options('(:any)', function() {});

// Auth Routes (Public)
$routes->post('auth/register', 'AuthController::register');
$routes->post('auth/login', 'AuthController::login');

// Protected Routes (Butuh Token)
$routes->group('api', ['filter' => 'authFilter'], function($routes) {
    // AI Chat
    $routes->post('chat', 'Api\AiController::chat');
    $routes->get('test-ai', 'Api\AiController::testConnection'); // <-- Tambahkan ini

    $routes->get('finance', 'Api\FinanceController::index');
    $routes->post('finance', 'Api\FinanceController::create'); // Tambah Income/Expense

    // Trading (Saham/Crypto)
    $routes->get('portfolio', 'Api\TradeController::portfolio');
    $routes->post('trade/buy', 'Api\TradeController::buy');  // Beli Saham
    $routes->post('trade/sell', 'Api\TradeController::sell'); // Jual Saham (BARU)

    $routes->get('market/price', 'Api\TradeController::getPrice');
    $routes->get('market/stocks', 'Api\TradeController::getMarketStocks');
});

$routes->group('api/admin', ['filter' => 'authFilter'], function($routes) {
    $routes->get('dashboard', 'Api\AdminController::dashboard');
    $routes->get('user-growth', 'Api\AdminController::getUserGrowth');
    
    $routes->get('users', 'Api\AdminController::users');
    $routes->post('users', 'Api\AdminController::createUser');
    $routes->put('users/(:num)', 'Api\AdminController::updateUser/$1');
    $routes->delete('users/(:num)', 'Api\AdminController::deleteUser/$1');

    $routes->get('transactions', 'Api\TransactionAdminController::index'); 
});