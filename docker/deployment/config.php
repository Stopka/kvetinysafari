<?php
declare(strict_types=1);

return [
    'app' => [
        'remote' => getenv ( 'REMOTE'),
        'local' => '/srv',
        'test' => false,
        'ignore' => '
			/deployment*
            .git*
            /www/sites
            /tmp
		',

        'allowDelete' => true,
    ],

    'tempDir' => '/tmp',
    'colors' => true,
    'filePermissions' => 0644,
    'dirPermissions' => 0755,
];
