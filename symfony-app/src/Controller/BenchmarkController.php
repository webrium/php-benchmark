<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class BenchmarkController extends AbstractController
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

    #[Route('/bench/render', name: 'bench_render', methods: ['GET'])]
    public function benchRender(): Response
    {
        $users = $this->users();
        $stats = [
            'total'    => count($users),
            'active'   => count(array_filter($users, fn($u) => $u['active'])),
            'inactive' => count(array_filter($users, fn($u) => $u['active'])),
        ];

        return $this->render('bench/index.html.twig', [
            'users' => $users,
            'stats' => $stats,
        ]);
    }

    #[Route('/bench/json', name: 'bench_json', methods: ['GET'])]
    public function benchJson(): JsonResponse
    {
        return $this->json(['data' => $this->users()]);
    }
}
