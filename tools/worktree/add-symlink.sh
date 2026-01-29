#!/bin/bash
#
# add-symlink.sh
#
# Git worktree 환경에서 main worktree의 특정 디렉토리들을 symlink로 연결합니다.
#
# Usage:
#   ./tools/worktree/add-symlink.sh [디렉토리1] [디렉토리2] ...
#
# Example:
#   ./tools/worktree/add-symlink.sh .context          # 로그 중앙화
#   ./tools/worktree/add-symlink.sh node_modules      # 의존성 공유
#   ./tools/worktree/add-symlink.sh .context node_modules
#
# 인자가 없으면 기본으로 .context를 symlink 합니다.
#
# .context Symlink 동작:
#   - worktree에서 .context -> main/.context로 연결
#   - worktree의 로그는 main/.context/{worktree-name}/logs/에 저장
#   - main에서 모든 worktree 로그를 한눈에 확인 가능

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 현재 디렉토리가 git repository인지 확인
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "현재 디렉토리가 git repository가 아닙니다."
    exit 1
fi

# Main worktree 경로 찾기
get_main_worktree_path() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir)

    # git-common-dir이 .git으로 끝나면 그 부모가 main worktree
    if [[ "$git_common_dir" == */.git ]]; then
        dirname "$git_common_dir"
    elif [[ "$git_common_dir" == ".git" ]]; then
        # 현재가 main worktree
        pwd
    else
        # worktree의 경우 git-common-dir은 main/.git/worktrees/name 형태
        # main/.git를 찾아서 그 부모 반환
        local main_git_dir
        main_git_dir=$(dirname "$(dirname "$git_common_dir")")
        dirname "$main_git_dir"
    fi
}

# 현재 worktree인지 main worktree인지 확인
is_worktree() {
    local git_dir
    git_dir=$(git rev-parse --git-dir)

    # .git이 파일이면 worktree, 디렉토리면 main
    if [[ -f ".git" ]]; then
        return 0  # true: worktree
    else
        return 1  # false: main worktree
    fi
}

# Symlink 생성
create_symlink() {
    local target_dir=$1
    local main_path=$2
    local current_path
    current_path=$(pwd)

    local source="${main_path}/${target_dir}"
    local dest="${current_path}/${target_dir}"

    # Main worktree에 소스 디렉토리가 있는지 확인
    if [[ ! -d "$source" ]]; then
        log_warn "Main worktree에 '${target_dir}'가 존재하지 않습니다. 스킵합니다."
        return 0
    fi

    # 이미 symlink가 있는 경우
    if [[ -L "$dest" ]]; then
        local existing_target
        existing_target=$(readlink "$dest")
        if [[ "$existing_target" == "$source" ]]; then
            log_info "'${target_dir}' symlink가 이미 올바르게 설정되어 있습니다."
        else
            log_warn "'${target_dir}' symlink가 다른 경로를 가리키고 있습니다. 업데이트합니다."
            rm "$dest"
            ln -s "$source" "$dest"
            log_info "'${target_dir}' symlink를 업데이트했습니다."
        fi
        return 0
    fi

    # 실제 디렉토리가 있는 경우
    if [[ -d "$dest" ]]; then
        log_warn "'${target_dir}' 디렉토리가 이미 존재합니다. 백업 후 symlink를 생성합니다."
        mv "$dest" "${dest}.backup.$(date +%Y%m%d%H%M%S)"
        log_info "'${target_dir}'를 백업했습니다."
    fi

    # Symlink 생성
    ln -s "$source" "$dest"
    log_info "'${target_dir}' → '${source}' symlink를 생성했습니다."

    # .context symlink인 경우, worktree용 로그 디렉토리 자동 생성
    if [[ "$target_dir" == ".context" ]]; then
        local worktree_name
        worktree_name=$(basename "$current_path")
        local worktree_log_dir="$source/$worktree_name/logs"

        if [[ ! -d "$worktree_log_dir" ]]; then
            mkdir -p "$worktree_log_dir"
            log_info "Worktree 로그 디렉토리 생성: $worktree_log_dir"
        fi
    fi
}

# 기본 symlink 대상 디렉토리
DEFAULT_DIRS=(".context")

# Main
main() {
    local main_worktree_path
    main_worktree_path=$(get_main_worktree_path)

    local current_path
    current_path=$(pwd)

    log_info "Main worktree 경로: ${main_worktree_path}"
    log_info "현재 경로: ${current_path}"

    # Main worktree에서 실행한 경우
    if [[ "$main_worktree_path" == "$current_path" ]]; then
        log_info "현재 main worktree에서 실행 중입니다. Symlink가 필요하지 않습니다."
        exit 0
    fi

    # Symlink 대상 디렉토리 결정
    local dirs=()
    if [[ $# -gt 0 ]]; then
        dirs=("$@")
    else
        dirs=("${DEFAULT_DIRS[@]}")
    fi

    log_info "Symlink 대상: ${dirs[*]}"
    echo ""

    # 각 디렉토리에 대해 symlink 생성
    for dir in "${dirs[@]}"; do
        create_symlink "$dir" "$main_worktree_path"
    done

    echo ""
    log_info "Worktree symlink 설정이 완료되었습니다."
}

main "$@"
