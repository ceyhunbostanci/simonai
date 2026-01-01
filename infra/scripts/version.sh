#!/bin/bash
# Simon AI Agent Studio - Version Management & Rollback
# Kullanım: ./scripts/version.sh [command] [args]

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonksiyonlar
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Geçerli versiyon bilgisi
get_current_version() {
    grep '"version"' package.json | head -1 | awk -F'"' '{print $4}'
}

# Yeni sürüm oluştur
create_release() {
    local version_type=$1
    
    if [[ ! "$version_type" =~ ^(major|minor|patch)$ ]]; then
        log_error "Geçersiz sürüm tipi. Kullanım: major|minor|patch"
        exit 1
    fi
    
    local current_version=$(get_current_version)
    log_info "Mevcut sürüm: v$current_version"
    
    # Değişiklikleri kontrol et
    if [[ -n $(git status -s) ]]; then
        log_error "Uncommitted değişiklikler var. Önce commit yapın."
        exit 1
    fi
    
    # Sürüm numarasını artır
    log_info "Sürüm numarası artırılıyor ($version_type)..."
    npm version $version_type --no-git-tag-version
    
    local new_version=$(get_current_version)
    log_info "Yeni sürüm: v$new_version"
    
    # Changelog güncelle
    log_info "CHANGELOG.md güncelleniyor..."
    create_changelog_entry "$new_version"
    
    # Git commit ve tag
    git add package.json CHANGELOG.md
    git commit -m "chore: bump version to v$new_version"
    git tag -a "v$new_version" -m "Release v$new_version"
    
    log_info "✅ Sürüm v$new_version oluşturuldu"
    log_warn "Push için: git push && git push --tags"
}

# Changelog entry oluştur
create_changelog_entry() {
    local version=$1
    local date=$(date +%Y-%m-%d)
    
    # Eğer CHANGELOG.md yoksa oluştur
    if [ ! -f CHANGELOG.md ]; then
        cat > CHANGELOG.md << EOF
# Changelog

Tüm önemli değişiklikler bu dosyada dokümante edilir.

Format [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) standardına uygundur.

EOF
    fi
    
    # Yeni entry ekle
    sed -i "3i\\
## [${version}] - ${date}\\
\\
### Added\\
- Yeni özellikler buraya\\
\\
### Changed\\
- Değişiklikler buraya\\
\\
### Fixed\\
- Düzeltmeler buraya\\
\\
" CHANGELOG.md
}

# Rollback
rollback() {
    local target_version=$1
    
    if [ -z "$target_version" ]; then
        log_error "Hedef sürüm belirtilmedi. Kullanım: ./version.sh rollback v3.1.0"
        exit 1
    fi
    
    # Tag'in var olduğunu kontrol et
    if ! git rev-parse "$target_version" >/dev/null 2>&1; then
        log_error "Sürüm $target_version bulunamadı"
        exit 1
    fi
    
    log_warn "⚠️  UYARI: $target_version sürümüne geri dönülecek"
    read -p "Devam etmek istiyor musunuz? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "İşlem iptal edildi"
        exit 0
    fi
    
    # Mevcut değişiklikleri yedekle
    local backup_branch="backup-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$backup_branch"
    log_info "Mevcut durum yedeklendi: $backup_branch"
    
    # Hedef sürüme dön
    git checkout main
    git reset --hard "$target_version"
    
    log_info "✅ Rollback tamamlandı: $target_version"
    log_warn "Production'a push için: git push origin main --force"
    log_info "Yedek branch: $backup_branch"
}

# Sürüm listesi
list_versions() {
    log_info "Mevcut sürümler:"
    git tag -l "v*" --sort=-version:refname | head -20
}

# Sürüm karşılaştır
compare_versions() {
    local version1=$1
    local version2=${2:-HEAD}
    
    log_info "Karşılaştırma: $version1...$version2"
    git log "$version1...$version2" --oneline --graph --decorate
}

# Docker snapshot
docker_snapshot() {
    local version=$(get_current_version)
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local snapshot_name="simon-ai-snapshot-v${version}-${timestamp}"
    
    log_info "Docker snapshot oluşturuluyor: $snapshot_name"
    
    # Tüm servisleri durdur ve yedekle
    docker compose down
    
    # Volume backup
    docker run --rm \
        -v simon-ai-agent-studio_postgres-data:/data \
        -v $(pwd)/backups:/backup \
        alpine tar czf /backup/${snapshot_name}-postgres.tar.gz -C /data .
    
    docker run --rm \
        -v simon-ai-agent-studio_redis-data:/data \
        -v $(pwd)/backups:/backup \
        alpine tar czf /backup/${snapshot_name}-redis.tar.gz -C /data .
    
    log_info "✅ Snapshot kaydedildi: ./backups/${snapshot_name}-*.tar.gz"
}

# Restore from snapshot
docker_restore() {
    local snapshot_pattern=$1
    
    if [ -z "$snapshot_pattern" ]; then
        log_error "Snapshot adı belirtilmedi"
        log_info "Mevcut snapshot'lar:"
        ls -lh backups/ 2>/dev/null || log_warn "Backup bulunamadı"
        exit 1
    fi
    
    log_warn "⚠️  UYARI: Mevcut veriler silinecek!"
    read -p "Devam etmek istiyor musunuz? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "İşlem iptal edildi"
        exit 0
    fi
    
    docker compose down -v
    
    # Restore PostgreSQL
    docker run --rm \
        -v simon-ai-agent-studio_postgres-data:/data \
        -v $(pwd)/backups:/backup \
        alpine sh -c "cd /data && tar xzf /backup/${snapshot_pattern}-postgres.tar.gz"
    
    # Restore Redis
    docker run --rm \
        -v simon-ai-agent-studio_redis-data:/data \
        -v $(pwd)/backups:/backup \
        alpine sh -c "cd /data && tar xzf /backup/${snapshot_pattern}-redis.tar.gz"
    
    log_info "✅ Restore tamamlandı"
    log_info "Servisleri başlatmak için: docker compose up -d"
}

# Ana komut dispatcher
case "${1:-help}" in
    release)
        create_release "${2:-patch}"
        ;;
    rollback)
        rollback "$2"
        ;;
    list)
        list_versions
        ;;
    compare)
        compare_versions "$2" "$3"
        ;;
    snapshot)
        docker_snapshot
        ;;
    restore)
        docker_restore "$2"
        ;;
    help|*)
        cat << EOF
Simon AI Agent Studio - Sürüm Yönetimi

Kullanım:
  ./scripts/version.sh [command] [args]

Komutlar:
  release [major|minor|patch]  Yeni sürüm oluştur (varsayılan: patch)
  rollback <version>           Belirtilen sürüme geri dön
  list                         Mevcut sürümleri listele
  compare <v1> [v2]            İki sürümü karşılaştır
  snapshot                     Docker volume snapshot oluştur
  restore <snapshot-name>      Snapshot'tan geri yükle
  help                         Bu yardım mesajını göster

Örnekler:
  ./scripts/version.sh release patch       # v3.1.0 -> v3.1.1
  ./scripts/version.sh release minor       # v3.1.1 -> v3.2.0
  ./scripts/version.sh rollback v3.1.0     # v3.1.0'a geri dön
  ./scripts/version.sh snapshot            # Backup oluştur
  ./scripts/version.sh restore snapshot-v3.1.0-20250127-120000
EOF
        ;;
esac
