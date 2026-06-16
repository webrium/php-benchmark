<?php

namespace App\Controllers;

use CodeIgniter\HTTP\ResponseInterface;

class BenchmarkController extends BaseController
{
    private function users(): array
    {
        return [
            ['id' => 1,  'name' => 'Alice Johnson',  'email' => 'alice@example.com',  'role' => 'admin',  'active' => true],
            ['id' => 2,  'name' => 'Bob Smith',       'email' => 'bob@example.com',    'role' => 'editor', 'active' => true],
            ['id' => 3,  'name' => 'Carol Williams',  'email' => 'carol@example.com',  'role' => 'viewer', 'active' => false],
            ['id' => 4,  'name' => 'David Brown',     'email' => 'david@example.com',  'role' => 'editor', 'active' => true],
            ['id' => 5,  'name' => 'Eva Martinez',    'email' => 'eva@example.com',    'role' => 'viewer', 'active' => true],
            ['id' => 6,  'name' => 'Frank Garcia',    'email' => 'frank@example.com',  'role' => 'admin',  'active' => false],
            ['id' => 7,  'name' => 'Grace Lee',       'email' => 'grace@example.com',  'role' => 'viewer', 'active' => true],
            ['id' => 8,  'name' => 'Henry Wilson',    'email' => 'henry@example.com',  'role' => 'editor', 'active' => true],
            ['id' => 9,  'name' => 'Isla Anderson',   'email' => 'isla@example.com',   'role' => 'viewer', 'active' => false],
            ['id' => 10, 'name' => 'Jack Taylor',     'email' => 'jack@example.com',   'role' => 'editor', 'active' => true],
        ];
    }

    public function render(): string
    {
        $users = $this->users();
        $stats = [
            'total'    => count($users),
            'active'   => count(array_filter($users, fn($u) => $u['active'])),
            'inactive' => count(array_filter($users, fn($u) => !$u['active'])),
        ];

        return view('bench', ['users' => $users, 'stats' => $stats]);
    }

    public function json(): ResponseInterface
    {
        return $this->response->setJSON(['data' => $this->users()]);
    }
}
