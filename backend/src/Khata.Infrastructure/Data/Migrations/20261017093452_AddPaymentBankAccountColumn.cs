using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Khata.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentBankAccountColumn : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "BankAccountId",
                table: "payment",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_payment_BankAccountId",
                table: "payment",
                column: "BankAccountId");

            migrationBuilder.AddForeignKey(
                name: "FK_payment_business_bank_account_BankAccountId",
                table: "payment",
                column: "BankAccountId",
                principalTable: "business_bank_account",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_payment_business_bank_account_BankAccountId",
                table: "payment");

            migrationBuilder.DropIndex(
                name: "IX_payment_BankAccountId",
                table: "payment");

            migrationBuilder.DropColumn(
                name: "BankAccountId",
                table: "payment");
        }
    }
}
