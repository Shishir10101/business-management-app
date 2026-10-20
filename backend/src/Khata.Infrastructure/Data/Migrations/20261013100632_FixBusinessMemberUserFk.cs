using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Khata.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class FixBusinessMemberUserFk : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_business_member_app_user_AppUserId",
                table: "business_member");

            migrationBuilder.DropIndex(
                name: "IX_business_member_AppUserId",
                table: "business_member");

            migrationBuilder.DropColumn(
                name: "AppUserId",
                table: "business_member");

            migrationBuilder.AddForeignKey(
                name: "FK_business_member_app_user_UserId",
                table: "business_member",
                column: "UserId",
                principalTable: "app_user",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_business_member_app_user_UserId",
                table: "business_member");

            migrationBuilder.AddColumn<long>(
                name: "AppUserId",
                table: "business_member",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_business_member_AppUserId",
                table: "business_member",
                column: "AppUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_business_member_app_user_AppUserId",
                table: "business_member",
                column: "AppUserId",
                principalTable: "app_user",
                principalColumn: "Id");
        }
    }
}
