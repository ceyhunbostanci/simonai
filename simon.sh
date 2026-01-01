#!/bin/bash
# Simon AI Agent Studio - Quick Setup & Management
# Tek komutla kurulum ve yönetim

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
   _____ _                          ___    ____
  / ____(_)                        / _ \  |___ \
 | (___  _ _ __ ___   ___  _ __   / /_\ \   __) |
  \___ \| | '_ ` _ \ / _ \| '_ \  |  _  |  |__ <
  ____) | | | | | | | (_) | | | | | | | |  ___) |
 |_____/|_|_| |_| |_|\___/|_| |_| \_| |_/ |____/
                                                  
  Agent Studio MVP-1 v3.1
  Production Ready - 27 Aralık 2025
EOF
    echo -e "${NC}"
}

log_info() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "${BLUE}[→]${NC} $1"; }

# Gereksinimler kontrolü
check_requirements() {
    log_step "Gereksinimler kontrol ediliyor..."
    
    local missing=0
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker bulunamadı. Lütfen Docker kurulumunu yapın."
        missing=1
    else
        log_info "Docker: $(docker --version)"
    fi
    
    if ! command -v docker compose &> /dev/null; then
        log_error "Docker Compose bulunamadı."
        missing=1
    else
        log_info "Docker Compose: $(docker compose version)"
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Eksik gereksinimler var. Kuruluma devam edilemiyor."
        exit 1
    fi
    
    log_info "Tüm gereksinimler mevcut"
}

# Environment setup
setup_env() {
    log_step "Environment dosyası hazırlanıyor..."
    
    if [ ! -f .env ]; then
        cp .env.example .env
        log_info ".env dosyası oluşturuldu"
        log_warn "Lütfen .env dosyasını düzenleyip API anahtarlarınızı ekleyin"
        
        # Otomatik secret key oluştur
        SECRET_KEY=$(openssl rand -hex 32)
        sed -i "s/your-super-secret-key-change-me-in-production/${SECRET_KEY}/" .env
        log_info "Otomatik SECRET_KEY oluşturuldu"
        
        echo ""
        log_warn "Zorunlu API anahtarları (en az birini ekleyin):"
        echo "  - CLAUDE_API_KEY (önerilen)"
        echo "  - OPENAI_API_KEY"
        echo "  - GOOGLE_API_KEY"
        echo ""
        read -p "Şimdi .env dosyasını düzenlemek ister misiniz? (y/n) " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} .env
        fi
    else
        log_info ".env dosyası mevcut"
    fi
}

# First time setup
first_time_setup() {
    log_step "İlk kurulum yapılıyor..."
    
    # Create necessary directories
    mkdir -p backups logs screenshots evidence
    
    # Initialize git if not already
    if [ ! -d .git ]; then
        log_step "Git repository başlatılıyor..."
        git init
        git add .
        git commit -m "Initial commit - Simon AI Agent Studio v3.1.0"
        git tag -a v3.1.0 -m "Release v3.1.0"
        log_info "Git repository hazır"
    fi
    
    # Build Docker images
    log_step "Docker imajları oluşturuluyor (bu birkaç dakika sürebilir)..."
    docker compose build
    
    log_info "İlk kurulum tamamlandı"
}

# Start services
start_services() {
    local mode=${1:-production}
    
    log_step "Servisler başlatılıyor (mode: $mode)..."
    
    if [ "$mode" == "dev" ]; then
        docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
    else
        docker compose up -d
    fi
    
    log_info "Servisler başlatıldı"
    
    # Wait for health checks
    log_step "Servisler hazırlanıyor..."
    sleep 5
    
    # Show status
    docker compose ps
    
    echo ""
    log_info "Simon AI Agent Studio hazır!"
    echo ""
    echo -e "${CYAN}Erişim URL'leri:${NC}"
    echo "  📱 Web UI:    http://localhost:3000"
    echo "  🔧 API:       http://localhost:8000"
    echo "  📚 API Docs:  http://localhost:8000/docs"
    echo "  👨‍💼 Admin:     http://localhost:3001"
    echo ""
}

# Stop services
stop_services() {
    log_step "Servisler durduruluyor..."
    docker compose down
    log_info "Tüm servisler durduruldu"
}

# Show logs
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        docker compose logs -f
    else
        docker compose logs -f "$service"
    fi
}

# Health check
health_check() {
    log_step "Sistem sağlığı kontrol ediliyor..."
    
    local all_healthy=1
    
    # Check orchestrator
    if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
        log_info "Orchestrator: Healthy"
    else
        log_error "Orchestrator: Unhealthy"
        all_healthy=0
    fi
    
    # Check web
    if curl -sf http://localhost:3000 > /dev/null 2>&1; then
        log_info "Web UI: Healthy"
    else
        log_error "Web UI: Unhealthy"
        all_healthy=0
    fi
    
    # Check postgres
    if docker compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        log_info "PostgreSQL: Healthy"
    else
        log_error "PostgreSQL: Unhealthy"
        all_healthy=0
    fi
    
    # Check redis
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_info "Redis: Healthy"
    else
        log_error "Redis: Unhealthy"
        all_healthy=0
    fi
    
    if [ $all_healthy -eq 1 ]; then
        echo ""
        log_info "Tüm servisler sağlıklı çalışıyor"
    else
        echo ""
        log_warn "Bazı servisler sorunlu. Loglara bakın: ./simon.sh logs"
    fi
}

# Run tests
run_tests() {
    log_step "Testler çalıştırılıyor..."
    docker compose -f docker-compose.test.yml up --abort-on-container-exit
    docker compose -f docker-compose.test.yml down -v
}

# Clean everything
clean_all() {
    log_warn "⚠️  UYARI: Tüm veriler silinecek (volumes dahil)!"
    read -p "Devam etmek istiyor musunuz? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Temizlik yapılıyor..."
        docker compose down -v
        docker system prune -f
        log_info "Temizlik tamamlandı"
    else
        log_info "İşlem iptal edildi"
    fi
}

# Update system
update_system() {
    log_step "Sistem güncelleniyor..."
    
    git pull
    docker compose build
    docker compose up -d
    
    log_info "Güncelleme tamamlandı"
}

# Backup
backup_data() {
    ./infra/scripts/version.sh snapshot
}

# Main menu
show_menu() {
    show_banner
    
    echo "Kullanılabilir komutlar:"
    echo ""
    echo "  setup          İlk kurulumu yap"
    echo "  start          Servisleri başlat (production)"
    echo "  dev            Servisleri geliştirme modunda başlat"
    echo "  stop           Servisleri durdur"
    echo "  restart        Servisleri yeniden başlat"
    echo "  logs [servis]  Logları göster"
    echo "  health         Sistem sağlığını kontrol et"
    echo "  test           Testleri çalıştır"
    echo "  backup         Snapshot oluştur"
    echo "  clean          Tüm verileri temizle"
    echo "  update         Sistemi güncelle"
    echo "  help           Bu menüyü göster"
    echo ""
}

# Main command dispatcher
case "${1:-help}" in
    setup)
        show_banner
        check_requirements
        setup_env
        first_time_setup
        ;;
    start)
        show_banner
        start_services production
        ;;
    dev)
        show_banner
        start_services dev
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services production
        ;;
    logs)
        show_logs "$2"
        ;;
    health)
        health_check
        ;;
    test)
        run_tests
        ;;
    backup)
        backup_data
        ;;
    clean)
        clean_all
        ;;
    update)
        update_system
        ;;
    help|*)
        show_menu
        ;;
esac
