using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Khata.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddUserActiveBusiness : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_business_Name",
                table: "business");

            migrationBuilder.AddColumn<long>(
                name: "ActiveBusinessId",
                table: "app_user",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_business_Name",
                table: "business",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_app_user_ActiveBusinessId",
                table: "app_user",
                column: "ActiveBusinessId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_business_Name",
                table: "business");

            migrationBuilder.DropIndex(
                name: "IX_app_user_ActiveBusinessId",
                table: "app_user");

            migrationBuilder.DropColumn(
                name: "ActiveBusinessId",
                table: "app_user");

            migrationBuilder.CreateIndex(
                name: "IX_business_Name",
                table: "business",
                column: "Name",
                unique: true);
        }
    }
}
