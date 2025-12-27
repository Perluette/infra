#!/bin/bash

DRY_RUN=false
VM_MEM=2048
VM_CORES=2
VM_NET="virtio,bridge=vmbr0"
LIMIT_VM_ID=

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=true
            ;;
        --VM_MEM=*)
            VM_MEM="${arg#*=}"
            ;;
        --VM_CORES=*)
            VM_CORES="${arg#*=}"
            ;;
        --VM_NET=*)
            VM_NET="${arg#*=}"
            ;;
        --limit=*)
            LIMIT_VM_ID="${arg#*=}"
            ;;
        *)
            echo "❗  Unknown option: $arg (Usage: See README.md)"
            exit 1
            ;;
    esac
done

[ "$DRY_RUN" = true ] && echo "❗  Dry-run execution. This run is a simulation and will change no state of any file nor component." && echo
[ -n "$LIMIT_VM_ID" ] && echo "❗  Limited exection : $LIMIT_VM_ID" && echo

echo "Template description:"
echo "  - Memory  : $VM_MEM"
echo "  - Cores   : $VM_CORES"
echo "  - Network : $VM_NET"
echo

find . -mindepth 2 -type f -name "*.qcow2" -print0 | sort -z | while IFS= read -r -d '' GOLDEN; do
    DIR=$(basename "$(dirname "$GOLDEN")")
    VM_ID=${DIR%%-*}
    IMG_NAME=$(basename "$GOLDEN" .qcow2)
    VM_NAME="${IMG_NAME}-golden"

    if [ -n "$LIMIT_VM_ID" ]; then
        if ! [[ ",$LIMIT_VM_ID," == *",$VM_ID,"* ]]; then
            continue
        fi
    fi

    if ! [[ "$VM_ID" =~ ^[0-9]+$ ]]; then
        echo "❗  WARNING: no numeric VM_ID prefix in directory '$DIR' : see README.md"
        echo "    Skipping golden: $GOLDEN"
        echo
        continue
    fi

    echo "Found Golden: $GOLDEN"
    echo "Creating VM: $VM_NAME ($VM_ID)"

    [ "$DRY_RUN" = false ] && qm create "$VM_ID" \
        --name "$VM_NAME" \
        --memory "$VM_MEM" \
        --cores "$VM_CORES" \
        --net0 "$VM_NET" \
        --ostype l26 \
        --agent 1

    echo "Setting VM description"
    [ "$DRY_RUN" = false ] && qm set "$VM_ID" --description "TODO"

    echo "Importing disk $GOLDEN"
    [ "$DRY_RUN" = false ] && qm importdisk "$VM_ID" "$GOLDEN" local-lvm > /dev/null

    echo "Setting HW options"
    [ "$DRY_RUN" = false ] && qm set "$VM_ID" --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-"$VM_ID"-disk-0

    echo "Setting boot order"
    [ "$DRY_RUN" = false ] && qm set "$VM_ID" --boot order=scsi0

    echo "Setting cloud-init drive"
    [ "$DRY_RUN" = false ] && qm set "$VM_ID" --ide2 local-lvm:cloudinit

    echo "Setting cloud-init user/password"
    [ "$DRY_RUN" = false ] && qm set "$VM_ID" \
        --ciuser ubuntu \
        --cipassword ubuntu \
        --ipconfig0 ip=dhcp

    echo "Converting VM to template"
    [ "$DRY_RUN" = false ] && qm template "$VM_ID"

    echo
done
