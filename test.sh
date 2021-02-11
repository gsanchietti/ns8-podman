
cat <<EOF > traefik.te
module traefik 1.0;

require {
	type init_t;
	type admin_home_t;
	class file execute;
}

#============= init_t ==============
allow init_t admin_home_t:file execute;
EOF

checkmodule -M -m -o traefik.mod traefik.te
semodule_package -o traefik.pp -m traefik.mod
semodule -X 300 -i traefik.pp
