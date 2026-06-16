<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\View\View;
use Illuminate\Support\Facades\DB;

class BenchmarkController extends Controller
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

    public function render(): View
    {
        $users = $this->users();
        $stats = [
            'total'    => count($users),
            'active'   => count(array_filter($users, fn($u) => $u['active'])),
            'inactive' => count(array_filter($users, fn($u) => !$u['active'])),
        ];

        return view('bench', compact('users', 'stats'));
    }

    public function db(): View
    {
        $users = DB::table('users')->limit(10)->get()->map(fn($u) => (array) $u)->toArray();
        $stats = [
            'total'    => count($users),
            'active'   => count(array_filter($users, fn($u) => ($u['active'] ?? true))),
            'inactive' => count(array_filter($users, fn($u) => !($u['active'] ?? true))),
        ];

        return view('bench', compact('users', 'stats'));
    }

    public function json(): JsonResponse
    {
        return response()->json([
            'data' => $this->users(),
        ]);
    }
}
