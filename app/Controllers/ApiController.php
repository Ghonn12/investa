<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\HTTP\IncomingRequest;

/**
 * Base Controller untuk API
 * * @property IncomingRequest $request
 */
class ApiController extends ResourceController
{
    protected $format = 'json';

    protected function success($data, $message = 'Success', $code = 200)
    {
        return $this->respond([
            'status' => $code,
            'message' => $message,
            'data' => $data
        ], $code);
    }

    protected function error($message, $code = 400)
    {
        return $this->respond([
            'status' => $code,
            'message' => $message,
        ], $code);
    }
}