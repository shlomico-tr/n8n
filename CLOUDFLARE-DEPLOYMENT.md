# פריסת n8n עם Cloudflare Tunnel 🚀

מדריך שלב אחר שלב לפריסת n8n עם Cloudflare Tunnel ו-GitHub Container Registry.

## 📋 דרישות מוקדמות

- חשבון GitHub
- חשבון Cloudflare (חינם)
- שרת/VM עם Docker ו-Docker Compose
- דומיין ב-Cloudflare

---

## שלב 1: הגדרת GitHub Container Registry

### 1.1 הפעל את GitHub Actions

1. עבור אל הריפו שלך ב-GitHub
2. לך ל-**Settings** → **Actions** → **General**
3. וודא ש-**Actions permissions** מוגדר ל-"Allow all actions"

### 1.2 הרץ את ה-Workflow

1. עבור ל-**Actions** בריפו
2. בחר את "Build and Push Docker Image"
3. לחץ על **Run workflow** → **Run workflow**

זה יבנה את ה-Docker image ויעלה אותו ל-GitHub Container Registry.

### 1.3 הפוך את ה-Package לציבורי (אופציונלי)

אם אתה רוצה שה-image יהיה נגיש ללא אימות:

1. עבור לפרופיל שלך ב-GitHub
2. לחץ על **Packages**
3. בחר את ה-package `n8n`
4. עבור ל-**Package settings**
5. גלול למטה ל-**Danger Zone**
6. לחץ על **Change visibility** → **Public**

---

## שלב 2: הגדרת Cloudflare Tunnel

### 2.1 צור Tunnel חדש

1. היכנס ל-[Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. עבור ל-**Access** → **Tunnels**
3. לחץ על **Create a tunnel**
4. בחר **Cloudflared**
5. תן שם ל-tunnel (למשל: `n8n-production`)
6. לחץ **Save tunnel**

### 2.2 קבל את ה-Token

לאחר יצירת ה-tunnel, תקבל token שנראה כך:
```
eyJhIjoiYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY3ODkwIiwidCI6IjEyMzQ1Njc4LWFiY2QtZWZnaC1pamtsLW1ub3BxcnN0dXZ3eCIsInMiOiJhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ejEyMzQ1Njc4OTBhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ejEyIn0=
```

**שמור את ה-Token הזה!** תצטרך אותו בשלב הבא.

### 2.3 הגדר Public Hostname

1. בדף ה-tunnel, לחץ על **Public Hostname**
2. לחץ **Add a public hostname**
3. הגדר:
   - **Subdomain**: `n8n` (או כל שם שתרצה)
   - **Domain**: בחר את הדומיין שלך
   - **Type**: `HTTP`
   - **URL**: `n8n:5678`
4. לחץ **Save hostname**

עכשיו ה-URL שלך יהיה: `https://n8n.yourdomain.com`

---

## שלב 3: הגדרת השרת

### 3.1 התקן Docker ו-Docker Compose

אם עדיין לא מותקן:

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# התקן Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3.2 העתק קבצים לשרת

העלה את הקבצים הבאים לשרת:
- `docker-compose.cloudflare.yml`
- `cloudflare-deployment.env.example`

```bash
# בשרת, צור תיקייה חדשה
mkdir -p ~/n8n-production
cd ~/n8n-production

# העתק את הקבצים (דוגמה עם scp)
scp docker-compose.cloudflare.yml user@server:~/n8n-production/
scp cloudflare-deployment.env.example user@server:~/n8n-production/.env
```

### 3.3 ערוך את קובץ ה-.env

```bash
cd ~/n8n-production
nano .env
```

עדכן את הערכים הבאים:

```bash
# שם המשתמש שלך ב-GitHub
GITHUB_USERNAME=your-github-username

# הדומיין שלך (מה שהגדרת ב-Cloudflare)
N8N_HOST=n8n.yourdomain.com
WEBHOOK_URL=https://n8n.yourdomain.com

# סיסמת PostgreSQL חזקה
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# מפתח הצפנה - חובה לייצר!
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# ה-Token מ-Cloudflare
CLOUDFLARE_TUNNEL_TOKEN=your-actual-token-from-step-2.2
```

---

## שלב 4: הפעל את n8n

### 4.1 התחל את השירותים

```bash
cd ~/n8n-production
docker-compose -f docker-compose.cloudflare.yml up -d
```

### 4.2 בדוק שהכל עובד

```bash
# בדוק שהקונטיינרים רצים
docker-compose -f docker-compose.cloudflare.yml ps

# צפה בלוגים
docker-compose -f docker-compose.cloudflare.yml logs -f n8n
```

### 4.3 גישה ל-n8n

פתח את הדפדפן וגש אל:
```
https://n8n.yourdomain.com
```

---

## 🔧 פקודות שימושיות

### עצור את השירותים
```bash
docker-compose -f docker-compose.cloudflare.yml down
```

### הפעל מחדש
```bash
docker-compose -f docker-compose.cloudflare.yml restart
```

### עדכן ל-image חדש
```bash
# משוך את ה-image החדש
docker-compose -f docker-compose.cloudflare.yml pull

# הפעל מחדש
docker-compose -f docker-compose.cloudflare.yml up -d
```

### גבה את הנתונים
```bash
# גבה את PostgreSQL
docker exec -t n8n-production-postgres-1 pg_dump -U n8n n8n > backup-$(date +%Y%m%d).sql

# גבה את n8n data
docker run --rm -v n8n-production_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n-data-$(date +%Y%m%d).tar.gz -C /data .
```

### שחזר מגיבוי
```bash
# שחזר PostgreSQL
cat backup-20250110.sql | docker exec -i n8n-production-postgres-1 psql -U n8n -d n8n

# שחזר n8n data
docker run --rm -v n8n-production_n8n_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar xzf /backup/n8n-data-20250110.tar.gz"
```

---

## 🔒 אבטחה מומלצת

### 1. הפעל HTTPS בלבד
Cloudflare כבר מספק SSL אוטומטית! ✅

### 2. הגדר אימות

הוסף משתמשים ב-n8n:
```
Settings → Users → Invite Users
```

### 3. הגבל גישה לפי IP (אופציונלי)

ב-Cloudflare:
1. עבור ל-**Security** → **WAF**
2. צור חוק חדש שמאפשר גישה רק מ-IP ספציפי

### 4. הפעל 2FA

ב-n8n, עבור ל:
```
Settings → Personal → Security → Enable Two-Factor Authentication
```

---

## 🚀 עדכון אוטומטי

GitHub Actions יבנה אוטומטית image חדש כל פעם שתעשה push ל-`master`/`main`.

כדי לעדכן את השרת:

```bash
cd ~/n8n-production
docker-compose -f docker-compose.cloudflare.yml pull
docker-compose -f docker-compose.cloudflare.yml up -d
```

או צור cron job שיעדכן אוטומטית:

```bash
# הוסף ל-crontab
crontab -e

# הוסף שורה זו (עדכון יומי ב-3 בלילה)
0 3 * * * cd ~/n8n-production && docker-compose -f docker-compose.cloudflare.yml pull && docker-compose -f docker-compose.cloudflare.yml up -d > /tmp/n8n-update.log 2>&1
```

---

## 🐛 פתרון בעיות

### n8n לא נגיש
```bash
# בדוק שהקונטיינרים רצים
docker ps

# בדוק לוגים
docker-compose -f docker-compose.cloudflare.yml logs n8n
docker-compose -f docker-compose.cloudflare.yml logs cloudflared
```

### שגיאת Database Connection
```bash
# בדוק ש-PostgreSQL רץ
docker-compose -f docker-compose.cloudflare.yml logs postgres

# אפס את PostgreSQL (זהירות! ימחק נתונים)
docker-compose -f docker-compose.cloudflare.yml down -v
docker-compose -f docker-compose.cloudflare.yml up -d
```

### שגיאת Cloudflare Tunnel
```bash
# בדוק את ה-Token
docker-compose -f docker-compose.cloudflare.yml logs cloudflared

# ודא שה-CLOUDFLARE_TUNNEL_TOKEN נכון בקובץ .env
```

---

## 📊 ניטור

### הוסף healthcheck endpoint

הוסף ל-`docker-compose.cloudflare.yml` תחת `n8n`:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### צפה בשימוש במשאבים
```bash
docker stats
```

---

## ✨ השינויים המותאמים שלך

ה-image הזה כולל את השינויים שלך:
- ✅ טלמטריה מבוטלת
- ✅ AI features מופעלים כברירת מחדל
- ✅ כל התכונות של License זמינות

---

## 🆘 צריך עזרה?

- בדוק את [תיעוד n8n](https://docs.n8n.io)
- בדוק את [תיעוד Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- פתח issue ב-GitHub

---

**בהצלחה! 🎉**

