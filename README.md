# КР №2 — публикация приложения на защищённом сервере

Сальников Илья Андреевич · ЭФБО-11-24 · №23 по списку → вариант 3.

Шаблон: https://gitverse.ru/dgimatdinov/kr2-template

## Конфигурация

- Ubuntu 22.04, отдельная VirtualBox VM `devops-vm-salnikov`.
- Host-only IP: `192.168.57.23`, SSH: `devops@192.168.57.23:2222`.
- Приложение: `https://stats.devops.local` через Nginx.
- Docker-порт: только `127.0.0.1:8003`; Redis не опубликован.
- Секрет генерируется на VM; `chmod 600 .env`. В Git только `.env.example`.
- Redis 7 Alpine, пароль, AOF, том `redis_data`, healthcheck.
- Оба процесса работают с UID 999, не root.

## Развёртывание на подготовленной VM

Доставить файлы в `~/kr2` через rsync с `--exclude=.env --exclude=.git`.
Сначала проверить `--dry-run`. На сервере:

```sh
bash scripts/deploy.sh
bash scripts/verify.sh
```

На хосте добавить `192.168.57.23 stats.devops.local devops.local` в hosts,
скопировать **публичный** сертификат `/etc/ssl/certs/kr2.crt` и проверить:

```sh
curl --cacert kr2.crt https://stats.devops.local/
curl --cacert kr2.crt https://stats.devops.local/whoami
```

Ревизия исходного шаблона: [docs/review.md](docs/review.md).

## Полученные результаты

- Счётчик до пересоздания: 4, после `down` / `up`: 5; том сохранён.
- HTTP → HTTPS: 301. Без доверия сертификату curl возвращает 60,
  с `--cacert` запрос успешен.
- `/whoami`: `scheme: https`, `client: 192.168.57.1`, `host: stats.devops.local`.
  TCP-соединение с приложением устанавливает Nginx, поэтому исходный IP
  передаётся им в X-Real-IP. Нельзя доверять произвольному клиентскому X-Forwarded-For.
- Порты 8003 и 6379 недоступны с Windows в обход Nginx.
- Исходные ресурсы `devops.local/` и `/app/` доступны, правила UFW не изменены.
- Аудит: 22 успешные проверки. При публикации на 0.0.0.0 аудит возвращает 1;
  после восстановления loopback — 0.
- После изменения только комментария app.py слои установки зависимостей CACHED.

PR оставлен открытым до защиты, согласно методическим указаниям.
