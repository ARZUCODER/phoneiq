# PhoneIQ — serverga (droplet) yuklash qo'llanmasi

Bu backendni **ilm-ai loyihangizga umuman tegmasdan** o'rnatadi:
- alohida Docker konteyner (`phoneiq-api`),
- alohida port **8090** (faqat `127.0.0.1` ga ochiq, tashqaridan ko'rinmaydi),
- alohida nginx subdomeni.

ilm-ai (Go) va uning Postgres'i (5433) o'z holida qoladi.

---

## 0. Talablar (serverda)
- Docker + Docker Compose o'rnatilgan bo'lsin:
  ```bash
  docker --version && docker compose version
  ```
  Agar yo'q bo'lsa: `curl -fsSL https://get.docker.com | sh`

## 1. Loyihani serverga yuklash
O'z kompyuteringizdan (PowerShell):
```bash
scp -r C:\Users\Diyorbek\Documents\ARZU-APPS\phoneiq root@SERVER_IP:/opt/phoneiq
```
`service-account.json` git'ga kirmaydi, shuning uchun uni alohida yuklang:
```bash
scp C:\Users\Diyorbek\Documents\ARZU-APPS\ilm_ai\backend\service-account.json root@SERVER_IP:/opt/phoneiq/backend/service-account.json
```

## 2. Konteynerni ishga tushirish
Serverda:
```bash
cd /opt/phoneiq/deploy
bash deploy.sh
```
Bu image'ni build qiladi va `phoneiq-api` konteynerini `127.0.0.1:8090` da ishga tushiradi.
Tekshirish:
```bash
curl http://127.0.0.1:8090/health
```
`{"status":"ok","catalog_size":18}` chiqsa — ishladi.

## 3. Nginx subdomen + HTTPS
1. DNS'da `phoneiq-api.arzucoder.uz` uchun **A record** → SERVER_IP qo'shing.
2. Nginx config'ni o'rnating:
   ```bash
   cp /opt/phoneiq/deploy/nginx-phoneiq.conf /etc/nginx/sites-available/phoneiq
   ln -s /etc/nginx/sites-available/phoneiq /etc/nginx/sites-enabled/
   nginx -t && systemctl reload nginx
   ```
3. HTTPS sertifikat (mixed-content xatosi bo'lmasligi uchun **shart**):
   ```bash
   certbot --nginx -d phoneiq-api.arzucoder.uz
   ```

Endi backend `https://phoneiq-api.arzucoder.uz` da ishlaydi.

## 4. Frontendni shu backendga ulash
O'z kompyuteringizda:
```bash
cd C:\Users\Diyorbek\Documents\ARZU-APPS\phoneiq\app
flutter build web --dart-define=API_BASE=https://phoneiq-api.arzucoder.uz
firebase deploy --only hosting --project phoneiq-ai-2026
```
Endi https://phoneiq-ai-2026.web.app to'liq jonli ishlaydi (backend serverda).

## 5. Yangilash (keyin kod o'zgartirsangiz)
```bash
cd /opt/phoneiq && git pull
cd deploy && bash deploy.sh
```

---

## Docker'siz muqobil (systemd)
Agar Docker ishlatmasangiz:
```bash
cd /opt/phoneiq/backend
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
```
`/etc/systemd/system/phoneiq.service`:
```ini
[Unit]
Description=PhoneIQ API
After=network.target

[Service]
WorkingDirectory=/opt/phoneiq/backend
Environment=GOOGLE_CLOUD_PROJECT=ilm-ai-app
Environment=GOOGLE_APPLICATION_CREDENTIALS=/opt/phoneiq/backend/service-account.json
ExecStart=/opt/phoneiq/backend/.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8090
Restart=always

[Install]
WantedBy=multi-user.target
```
```bash
systemctl daemon-reload && systemctl enable --now phoneiq
```
Keyin 3- va 4-qadamlar bir xil.
