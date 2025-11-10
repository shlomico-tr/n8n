# התקנה מהירה של n8n עם Cloudflare ⚡

מדריך של 10 דקות להפעלת n8n עם Cloudflare Tunnel.

---

## שלב 1: בנה את ה-Image ב-GitHub (2 דקות)

1. Push את הקוד ל-GitHub:
```bash
cd /Users/shlomico/n8n
git add .
git commit -m "Add Cloudflare deployment config"
git push origin master
```

2. בדפדפן, עבור ל-GitHub → **Actions** → בחר "Build and Push Docker Image" → **Run workflow**

3. המתן עד שה-build יסתיים (כ-5-10 דקות)

---

## שלב 2: צור Cloudflare Tunnel (3 דקות)

1. היכנס ל-[Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. **Access** → **Tunnels** → **Create a tunnel**
3. שם: `n8n-production`
4. **העתק את ה-Token** (נראה כמו: `eyJh...`)
5. **Public Hostname**:
   - Subdomain: `n8n`
   - Domain: הדומיין שלך
   - Service: `HTTP` | `n8n:5678`
6. **Save**

---

## שלב 3: הפעל בשרת (5 דקות)

### בשרת שלך:

```bash
# צור תיקייה
mkdir -p ~/n8n && cd ~/n8n

# צור קובץ .env
nano .env
```

### הדבק את זה ב-.env (עדכן את הערכים!):

```bash
# שם המשתמש שלך ב-GitHub
GITHUB_USERNAME=your-github-username

# הדומיין שלך
N8N_HOST=n8n.yourdomain.com
WEBHOOK_URL=https://n8n.yourdomain.com
TIMEZONE=Asia/Jerusalem

# צור מפתח הצפנה
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# ה-Token שהעתקת משלב 2
CLOUDFLARE_TUNNEL_TOKEN=eyJh...your-token-here
```

### צור docker-compose.yml:

```bash
nano docker-compose.yml
```

הדבק את זה (גרסה פשוטה עם SQLite):

```yaml
version: '3.8'

services:
  n8n:
    image: ghcr.io/YOUR-GITHUB-USERNAME/n8n:latest
    restart: unless-stopped
    environment:
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=${TIMEZONE}
      - DB_TYPE=sqlite
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_AI_ENABLED=true
      - N8N_DIAGNOSTICS_ENABLED=false
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - n8n-network

  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - n8n-network
    depends_on:
      - n8n

volumes:
  n8n_data:

networks:
  n8n-network:
```

**זכור להחליף `YOUR-GITHUB-USERNAME` בשם המשתמש האמיתי שלך!**

### הפעל:

```bash
docker-compose up -d
```

### בדוק:

```bash
docker-compose logs -f
```

---

## ✅ סיימת!

גש אל: **https://n8n.yourdomain.com**

---

## 🔄 עדכון

כשיש image חדש:

```bash
cd ~/n8n
docker-compose pull
docker-compose up -d
```

---

## 🛠️ פקודות שימושיות

```bash
# צפה בלוגים
docker-compose logs -f n8n

# הפעל מחדש
docker-compose restart

# עצור
docker-compose down

# עצור ומחק הכל (זהירות!)
docker-compose down -v
```

---

## 💡 טיפים

1. **גיבוי**: הנתונים נשמרים ב-`n8n_data` volume
2. **PostgreSQL**: לשימוש ב-production, השתמש ב-`docker-compose.cloudflare.yml` (עם PostgreSQL)
3. **אבטחה**: הפעל 2FA ב-n8n Settings

---

## 🐛 בעיות?

### n8n לא נגיש
```bash
docker-compose logs n8n
docker-compose logs cloudflared
```

### שגיאת Tunnel
בדוק שה-`CLOUDFLARE_TUNNEL_TOKEN` נכון ב-.env

### ה-Image לא נמצא
וודא ש:
1. ה-build ב-GitHub Actions הסתיים בהצלחה
2. ה-Package הוא public (Settings → Package settings → Change visibility → Public)

---

**זהו! פשוט וקל 🎉**

