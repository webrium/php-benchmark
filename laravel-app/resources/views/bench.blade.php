<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Benchmark</title>
<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: #f1f5f9;
    color: #1e293b;
    padding: 2rem;
}
.container { max-width: 900px; margin: 0 auto; }
h1 { font-size: 1.25rem; font-weight: 600; margin-bottom: 1.5rem; color: #0f172a; }
.stats { display: flex; gap: 1rem; margin-bottom: 1.5rem; }
.stat {
    background: #fff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 1rem 1.5rem;
    flex: 1;
    text-align: center;
}
.stat-value { font-size: 1.75rem; font-weight: 700; color: #0f172a; }
.stat-label { font-size: 0.75rem; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-top: 0.25rem; }
table {
    width: 100%;
    border-collapse: collapse;
    background: #fff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    overflow: hidden;
}
thead { background: #f8fafc; }
th {
    padding: 0.75rem 1rem;
    text-align: left;
    font-size: 0.75rem;
    font-weight: 600;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    border-bottom: 1px solid #e2e8f0;
}
td {
    padding: 0.75rem 1rem;
    font-size: 0.875rem;
    border-bottom: 1px solid #f1f5f9;
    vertical-align: middle;
}
tr:last-child td { border-bottom: none; }
tr:hover td { background: #f8fafc; }
.badge {
    display: inline-block;
    padding: 0.2rem 0.6rem;
    border-radius: 999px;
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.04em;
}
.badge-admin  { background: #ede9fe; color: #6d28d9; }
.badge-editor { background: #dbeafe; color: #1d4ed8; }
.badge-viewer { background: #f1f5f9; color: #475569; }
.dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; }
.dot-on  { background: #22c55e; }
.dot-off { background: #cbd5e1; }
</style>
</head>
<body>
<div class="container">
    <h1>User List</h1>
    <div class="stats">
        <div class="stat">
            <div class="stat-value">{{ $stats['total'] }}</div>
            <div class="stat-label">Total</div>
        </div>
        <div class="stat">
            <div class="stat-value">{{ $stats['active'] }}</div>
            <div class="stat-label">Active</div>
        </div>
        <div class="stat">
            <div class="stat-value">{{ $stats['inactive'] }}</div>
            <div class="stat-label">Inactive</div>
        </div>
    </div>
    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($users as $user)
            <tr>
                <td>{{ $user['id'] }}</td>
                <td>{{ $user['name'] }}</td>
                <td>{{ $user['email'] }}</td>
                <td><span class="badge badge-{{ $user['role'] }}">{{ $user['role'] }}</span></td>
                <td><span class="dot {{ $user['active'] ? 'dot-on' : 'dot-off' }}"></span></td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>
</body>
</html>
