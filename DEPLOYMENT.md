# מדריך פריסה - n8n עם השינויים המותאמים שלך 🚀

מדריך מקיף לפריסת n8n עם הגרסה המותאמת שלך.

---

## 🎯 מה כלול בגרסה הזו?

הגרסה המותאמת שלך כוללת:

✅ **טלמטריה מבוטלת** - אין שליחת נתונים אנליטיים  
✅ **AI Features מופעלים** - AI Assistant, Ask AI, AI Builder  
✅ **License Features זמינים** - כל התכונות הפרימיום  
✅ **Personalization מבוטלת** - אין איסוף מידע אישי  

---

## 📚 מדריכי פריסה

בחר את שיטת הפריסה המתאימה לך:

### 🚀 מומלץ: Cloudflare Tunnel (הכי פשוט!)

**יתרונות:**
- אין צורך ב-IP ציבורי
- SSL חינם אוטומטי
- הגנת DDoS מובנית
- קל להתקנה

**מדריכים:**
- [📖 מדריך מפורט](./CLOUDFLARE-DEPLOYMENT.md) - כל הפרטים
- [⚡ התחלה מהירה](./QUICK-START-CLOUDFLARE.md) - 10 דקות
- [🤖 סקריפט אוטומטי](./setup-cloudflare.sh) - התקנה בקליק אחד

### 🐳 Docker ידני

**מתאים עבור:**
- פריסה על VM/שרת עם Docker
- שליטה מלאה בהגדרות
- שימוש ללא Cloudflare

**קבצים:**
- `docker-compose.cloudflare.yml` - עם PostgreSQL (production)
- `docker-compose.cloudflare-simple.yml` - עם SQLite (פשוט)

### ☁️ Azure / AWS / GCP

**לפריסה על ענן:**
1. השתמש ב-GitHub Actions לבניית image
2. העלה ל-Container Registry המתאים
3. פרוס עם Container Instances או Kubernetes

---

## 🔨 בניית Docker Image

### אופציה 1: GitHub Actions (מומלץ)

הבניה מתבצעת אוטומטית ב-GitHub:

1. **Push לריפו:**
```bash
git add .
git commit -m "Deploy n8n"
git push origin master
```

2. **הרץ Workflow:**
   - GitHub → Actions
   - "Build and Push Docker Image"
   - Run workflow

3. **ה-Image זמין ב:**
```
ghcr.io/YOUR-USERNAME/n8n:latest
ghcr.io/YOUR-USERNAME/n8n:1.119.0-custom
```

### אופציה 2: בניה מקומית

אם Docker Desktop עובד אצלך:

```bash
cd /Users/shlomico/n8n

# בנה את האפליקציה
export PATH="/Users/shlomico/.local/bin:$PATH"
node scripts/build-n8n.mjs

# בנה את ה-Docker image
node scripts/dockerize-n8n.mjs

# תייג ודחוף
docker tag n8nio/n8n:local your-registry/n8n:latest
docker push your-registry/n8n:latest
```

---

## 🚀 פריסה מהירה עם Cloudflare

### שלב 1: צור Cloudflare Tunnel

1. [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Access → Tunnels → Create a tunnel
3. שם: `n8n-production`
4. **שמור את ה-Token**

### שלב 2: הגדר Public Hostname

- Subdomain: `n8n`
- Domain: הדומיין שלך
- Service: `HTTP` | `n8n:5678`

### שלב 3: הרץ בשרת

```bash
# העלה את הסקריפט לשרת
scp setup-cloudflare.sh user@server:~/

# בשרת
bash ~/setup-cloudflare.sh
```

או באופן ידני:

```bash
# צור תיקייה
mkdir ~/n8n && cd ~/n8n

# צור .env
cat > .env << EOF
GITHUB_USERNAME=your-username
N8N_HOST=n8n.yourdomain.com
WEBHOOK_URL=https://n8n.yourdomain.com
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
CLOUDFLARE_TUNNEL_TOKEN=your-token
EOF

# צור docker-compose.yml
wget https://raw.githubusercontent.com/YOUR-USERNAME/n8n/master/docker-compose.cloudflare-simple.yml -O docker-compose.yml

# הפעל
docker-compose up -d
```

---

## 🔧 ניהול ועדכונים

### צפה בלוגים
```bash
docker-compose logs -f n8n
```

### עדכן לגרסה חדשה
```bash
docker-compose pull
docker-compose up -d
```

### גיבוי
```bash
# גבה נתונים
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/n8n-backup-$(date +%Y%m%d).tar.gz -C /data .

# גבה PostgreSQL (אם רלוונטי)
docker exec postgres pg_dump -U n8n n8n > backup-$(date +%Y%m%d).sql
```

### שחזור
```bash
# שחזר נתונים
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine \
  tar xzf /backup/n8n-backup-20250110.tar.gz -C /data

# שחזר PostgreSQL
cat backup-20250110.sql | docker exec -i postgres psql -U n8n -d n8n
```

---

## 🔒 אבטחה

### הגדרות מומלצות

1. **שנה את ה-Encryption Key**
   ```bash
   # צור מפתח חדש
   openssl rand -hex 32
   
   # עדכן ב-.env
   N8N_ENCRYPTION_KEY=your-new-key
   ```

2. **הגבל גישה לפי IP** (Cloudflare)
   - Security → WAF → Create Rule
   - הגדר IP whitelist

3. **הפעל 2FA** ב-n8n
   - Settings → Security → Two-Factor Authentication

4. **השתמש ב-PostgreSQL** ב-production
   - יותר יציב ומהיר
   - תמיכה טובה יותר לעומסים גבוהים

---

## 📊 ניטור

### Healthcheck

הוסף ב-docker-compose:

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### משאבים

```bash
# צפה בשימוש
docker stats

# בדוק דיסק
df -h
```

---

## 🐛 פתרון בעיות

### n8n לא נגיש

```bash
# בדוק קונטיינרים
docker ps

# בדוק לוגים
docker-compose logs n8n
docker-compose logs cloudflared

# הפעל מחדש
docker-compose restart
```

### שגיאת Database

```bash
# PostgreSQL לא עובד
docker-compose logs postgres

# אפס database (זהירות!)
docker-compose down -v
docker-compose up -d
```

### שגיאת Cloudflare Tunnel

```bash
# בדוק token
docker-compose logs cloudflared

# וודא שה-token נכון ב-.env
cat .env | grep CLOUDFLARE_TUNNEL_TOKEN
```

---

## 📝 משתני סביבה

### משתנים חובה

```bash
N8N_HOST=n8n.yourdomain.com
WEBHOOK_URL=https://n8n.yourdomain.com
N8N_ENCRYPTION_KEY=your-32-char-key
CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token
```

### משתנים אופציונליים

```bash
# Timezone
GENERIC_TIMEZONE=Asia/Jerusalem

# Database (SQLite כברירת מחדל)
DB_TYPE=sqlite  # או postgresdb

# PostgreSQL
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=secure-password

# Executions
EXECUTIONS_TIMEOUT=3600
EXECUTIONS_TIMEOUT_MAX=7200
```

---

## 🎓 למידה נוספת

### תיעוד רשמי
- [n8n Documentation](https://docs.n8n.io)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

### קהילה
- [n8n Community Forum](https://community.n8n.io)
- [n8n Discord](https://discord.gg/n8n)

---

## 🆘 קיבלת תקוע?

1. בדוק את מדריכי הפתרון בעיות
2. צפה בלוגים: `docker-compose logs -f`
3. בדוק את [n8n Community Forum](https://community.n8n.io)
4. פתח issue ב-GitHub

---

## ✨ התכונות המותאמות שלך

זכור - הגרסה הזו כוללת:

- 🚫 אין טלמטריה
- 🤖 AI מופעל
- 🔓 כל תכונות ה-License
- 🎯 אופטימיזציות מותאמות

**בהצלחה עם n8n! 🎉**

