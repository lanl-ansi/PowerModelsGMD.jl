def open-pw-csv [pw_csv] {
    open -r $pw_csv | lines | skip 1 | to text | from csv
}
