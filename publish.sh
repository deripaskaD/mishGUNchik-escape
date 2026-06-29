#!/usr/bin/env bash
# Публикация «Побег от Мишганчика» на GitHub + веб-сборка на Pages.
# Запусти в Terminal.app:   bash /Users/MAKENZI/timokha-escape/publish.sh
set -e
cd /Users/MAKENZI/timokha-escape

REPO="mishGUNchik-escape"

echo "=== 1/4 Проверка авторизации gh ==="
if ! gh auth status >/dev/null 2>&1; then
  echo "Откроется браузер — вставь показанный код и нажми Authorize (ты уже залогинен в GitHub)."
  gh auth login --hostname github.com --git-protocol https --web
fi
OWNER=$(gh api user --jq .login)
echo "OK, аккаунт: $OWNER"

echo "=== 2/4 Создание репозитория $OWNER/$REPO (public) + push ==="
if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  echo "Репозиторий уже существует — добавляю remote и пушу."
  git remote add origin "https://github.com/$OWNER/$REPO.git" 2>/dev/null || true
  git push -u origin main
else
  gh repo create "$OWNER/$REPO" --public --source=. --remote=origin --push
fi

echo "=== 3/4 Включение GitHub Pages (source = GitHub Actions) ==="
gh api -X POST "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 \
  && echo "Pages включены." || echo "Pages уже включены или включатся workflow-ом."

echo "=== 4/4 Готово ==="
echo "GitHub Actions сейчас собирает веб-версию (~3-5 мин)."
echo "Прогресс сборки:  https://github.com/$OWNER/$REPO/actions"
echo "Ссылка для тестера (появится после сборки):  https://$OWNER.github.io/$REPO/"
echo
echo ">>> Напиши Claude 'готово' — он проверит сборку и подтвердит рабочую ссылку."
