<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */

// CORS Preflight
$routes->options('(:any)', function() {});

// --- AUTH ROUTES (Public) ---
// Karena AuthController ada di 'App\Controllers', panggil langsung tanpa prefix.
$routes->post('auth/register', '\App\Controllers\AuthController::register');
$routes->post('auth/login',    '\App\Controllers\AuthController::login');


// --- PROTECTED ROUTES (Butuh Token) ---
// Group API Default (Untuk Controller temanmu yang pakai prefix manual 'Api\...')
$routes->group('api', ['filter' => 'authFilter'], function($routes) {
    
    // Fitur Temanmu (AI & Trading)
    // Di sini temanmu menulis 'Api\AiController', jadi ini akan mencari di folder Api
    $routes->post('chat', 'Api\AiController::chat');
    $routes->get('test-ai', 'Api\AiController::testConnection');

    $routes->get('finance', 'Api\FinanceController::index');
    $routes->post('finance', 'Api\FinanceController::create');

    $routes->get('portfolio', 'Api\TradeController::portfolio');
    $routes->post('trade/buy', 'Api\TradeController::buy');
    $routes->post('trade/sell', 'Api\TradeController::sell');
    $routes->get('market/price', 'Api\TradeController::getPrice');
    $routes->get('market/stocks', 'Api\TradeController::getMarketStocks');
});

// --- FITUR SAKUKU (Finance Kita) ---
// Kita buat group khusus yang otomatis menambahkan namespace 'App\Controllers\Api'
// Jadi di dalamnya kita TIDAK PERLU nulis 'Api\' lagi.
$routes->group('api', ['namespace' => 'App\Controllers\Api', 'filter' => 'authFilter'], function($routes) {
    
    // CRUD Wallet
    $routes->resource('wallet', ['controller' => 'WalletController']);
    
    // CRUD Kategori
    $routes->resource('kategori', ['controller' => 'KategoriController']);
    
    // CRUD Transaksi
    $routes->resource('transaksi', ['controller' => 'TransaksiController']);
    
    // Dashboard
    $routes->get('dashboard/summary', 'DashboardController::summary');

    // User Management
    $routes->group('user', function($routes) {
        $routes->get('profile', 'UserController::profile');
        $routes->put('profile', 'UserController::updateProfile');
        $routes->put('password', 'UserController::changePassword');
    });
});

// --- ADMIN ROUTES ---
$routes->group('api/admin', ['filter' => 'authFilter'], function($routes) {
    $routes->get('dashboard', 'Api\AdminController::dashboard');
    $routes->get('user-growth', 'Api\AdminController::getUserGrowth');
    
    $routes->get('users', 'Api\AdminController::users');
    $routes->post('users', 'Api\AdminController::createUser');
    $routes->put('users/(:num)', 'Api\AdminController::updateUser/$1');
    $routes->delete('users/(:num)', 'Api\AdminController::deleteUser/$1');

    $routes->get('transactions', 'Api\TransactionAdminController::index'); 
});