<?php

// Read-only check: never creates sessions, resets passwords, or modifies users.
require __DIR__.'/../backend/vendor/autoload.php';
$app = require __DIR__.'/../backend/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$details = file_get_contents(__DIR__.'/../professor_handover/LOGIN_DETAILS.txt');
preg_match_all('/Email: (.+)\RPassword: (.+)\RRole: (.+)/', $details, $matches, PREG_SET_ORDER);
$failures = 0;
foreach ($matches as $match) {
    $user = App\Models\User::where('email', trim($match[1]))->first();
    $valid = $user && Illuminate\Support\Facades\Hash::check(trim($match[2]), $user->password)
        && $user->is_active && $user->account_status === 'approved';
    echo trim($match[3]).': '.($valid ? 'PASS' : 'FAIL').PHP_EOL;
    if (! $valid) {
        echo $user ? '  Password matches: '.(Illuminate\Support\Facades\Hash::check(trim($match[2]), $user->password) ? 'yes' : 'no')
            .'; active: '.($user->is_active ? 'yes' : 'no').'; status: '.$user->account_status.PHP_EOL
            : '  Account is not present.'.PHP_EOL;
    }
    $failures += ! $valid;
}
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
foreach (['/up', '/api/advisers'] as $path) {
    $request = Illuminate\Http\Request::create($path, 'GET');
    $request->headers->set('Accept', 'application/json');
    $response = $kernel->handle($request);
    echo $path.': HTTP '.$response->getStatusCode().PHP_EOL;
    $failures += $response->getStatusCode() !== 200;
    $kernel->terminate($request, $response);
}
exit(count($matches) === 6 && $failures === 0 ? 0 : 1);
