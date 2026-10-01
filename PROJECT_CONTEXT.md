# PROJECT_CONTEXT.md - Cây Nguyên Sinh

File này là **source of truth** cho thiết kế và trạng thái triển khai hiện tại. Đọc file trước khi sửa gameplay, progression, Main Area, Energy Stone, Region hoặc Boss. Khi code và tài liệu lệch nhau, phải kiểm tra code thực tế rồi cập nhật lại file này.

*Cập nhật trạng thái: 2026-09-28.*

## 1. Tổng Quan Chính Thức

- **Tên:** Cây Nguyên Sinh.
- **Thể loại:** 2D top-down action adventure.
- **Engine:** Godot 4.x, GDScript.
- **Nền tảng mục tiêu:** Android; bàn phím hiện dùng để test prototype.
- **Cấu trúc thế giới:** một Main Area kết nối tuần tự tới 5 Region, không phải open world.
- **Vòng lặp chính:** chiến đấu, thu Energy, đánh Boss, trở về Main Area, nạp Energy Stone và mở khóa cấp tiếp theo.

Thế giới được duy trì bởi 5 Viên Đá Năng Lượng: Water, Earth, Light, Air và Life. Sinh vật ở mỗi Region đã hấp thụ năng lượng của đá. Player là người bảo hộ đi thu hồi Energy và kích hoạt lại các viên đá.

Thiết kế cũ về giải cứu Cây Nguyên Sinh, 5 Core, Altar, Hub nhiều trạng thái và PrimordialTree đã bị loại bỏ. Không khôi phục các hệ thống đó nếu chưa có yêu cầu thiết kế mới.

## 2. Progression Cố Định

| Cấp | Region | Enemy | Boss | Energy yêu cầu | Phần thưởng | Region tiếp theo |
| --- | --- | --- | --- | ---: | --- | --- |
| 1 | Water | Bomb Fish, Paddle Shark | Turtle | 100 | Heal | Earth |
| 2 | Earth | Spider, Snake | Panda | 150 | Quyền trượng tấn công xa | Light |
| 3 | Light | Hex Shaman, Torch Goblin | Minotaur | 200 | Tấn công diện rộng | Air |
| 4 | Air | Imp, Bumblebee | Giant Bat | 250 | Nâng chỉ số | Life |
| 5 | Life | Thief, Spear Goblin | Troll | 300 | Chiến thắng | Kết thúc |

Quy tắc canonical:

- Thứ tự luôn là `Water -> Earth -> Light -> Air -> Life`; Water mở từ đầu.
- Chỉ viên đá hiện tại nhận Energy.
- Viên đá chỉ kích hoạt khi **đủ Energy và Boss tương ứng đã bị đánh bại**.
- Có thể nộp Energy từng phần; Energy vượt mức yêu cầu vẫn được giữ trong lượng đang mang.
- Kích hoạt đá mở phần thưởng và cổng tiếp theo. Life Stone đặt `game_completed = true`.
- Energy đang mang và tiến độ trong AutoLoad tồn tại khi đổi scene hoặc chết, nhưng hiện chưa được ghi ra save file.

## 3. Gameplay Loop

1. Main Menu đi qua Loading Screen tới Main Area.
2. Player tương tác với Lancer của Region đã mở.
3. Trong Region, Player tiêu diệt 24 quái nhỏ và nhặt Energy.
4. Khi quái cuối rời scene, Player bị khóa điều khiển tạm thời; cảnh báo hiện tên Boss và camera chuyển tới `BossSpawnPoint`.
5. Hiệu ứng triệu hồi chạy xong mới spawn Boss. Camera quay lại rồi Boss mới hoạt động.
6. Boss chết, rơi Energy; victory dialog chỉ mở sau khi toàn bộ boss pickup đã được nhặt.
7. Player trở về Main Area bằng Return Whirlpool hoặc lựa chọn trong dialog.
8. Player nói chuyện với Monk và nộp Energy vào viên đá hiện tại.
9. Khi đủ hai điều kiện, phần thưởng và Region tiếp theo được mở.

Mọi chuyển scene gameplay phải đi qua `SceneLoader` và `LoadingScreen.tscn`.

## 4. Trạng Thái Đã Triển Khai

### Main Area Và Điều Hướng

- Main Area: `res://scenes/maps/main.tscn`.
- 5 Energy Stone đã đặt quanh Monk, có animation lấp lánh và màu theo Region.
- Monk mở `EnergyStonePanel`: hiển thị đá hiện tại, Energy đã nạp/đang mang, trạng thái Boss, phần thưởng và thao tác nộp.
- Khi Monk nhận đủ Energy sau khi Boss tương ứng đã bị đánh bại, Main Area phát âm thanh chiến thắng, pháo hoa và overlay chúc mừng viên đá thức tỉnh.
- 5 Lancer đã có vùng tương tác, dialog xác nhận và kiểm tra khóa bằng `ProgressionManager`:
  - Blue: Water.
  - Black: Earth.
  - Yellow: Light.
  - Purple: Air.
  - Red: Life.
- Cả 5 Region có Return Whirlpool, Confirmation Dialog, encounter controller và victory controller dùng chung.
- Main Area có thêm một Sheep đứng yên mặc định, chạy tới waypoint an toàn xa Player nhất khi bị tiếp cận và hiện tiếng kêu ngẫu nhiên; bong bóng tự ẩn và có cooldown.
- Hai Pawn trang trí chặt cây và đào mỏ vàng. Khi Player đến gần, Pawn hiện bong bóng "I'm sorry!" rồi chạy tới điểm trú ẩn; sau khi Player rời đi, Pawn quay lại tiếp tục làm việc. Bong bóng tự ẩn và có cooldown; hoạt cảnh không sinh hoặc làm mất tài nguyên.
- Một Gold Pawn đứng gần Sheep, mặc định ôm vàng và đứng yên; khi Player đến gần sẽ hiện "0.o" rồi chạy tới điểm an toàn, sau đó quay lại vị trí ban đầu khi Player rời đi.

### Energy Và Progression

- `EnergyManager` quản lý Energy đang mang.
- `ProgressionManager` quản lý Energy từng đá, Boss đã hạ, Region/phần thưởng đã mở và trạng thái hoàn thành.
- Enemy thường luôn rơi ngẫu nhiên 1-5 Energy.
- Pickup có delay, hiệu ứng, hút về Player trong bán kính gần và cộng Energy khi chạm.
- Boss rơi cố định 30 Energy dưới dạng 6 pickup, mỗi pickup 5.
- HUD hiển thị Energy đang mang.
- Logic mở khóa cho cả 5 phần thưởng đã có trong progression data.
- Sau khi kích hoạt Air Stone, Player có thể tương tác trực tiếp với cả 5 Energy Stone để nâng chỉ số tối đa 5 cấp bằng Energy đang mang. Chi phí lần lượt là 25, 50, 75, 100 và 125 Energy.
- Water tăng 10 Max Mana/cấp; Earth tăng 5 lượng Heal/cấp; Light tăng 10 sát thương kiếm và 2 sát thương trượng/cấp; Air tăng 15 sát thương Area Attack/cấp; Life tăng 10 Max HP/cấp.

### Player Và Điều Khiển

- Di chuyển 8 hướng, kiếm cận chiến, dash, HP, Mana, damage, invincibility và knockback.
- Heal đã triển khai và bị khóa bởi progression: tốn 25 Mana, hồi 30 HP, cooldown 5 giây.
- Mana tự hồi 4 điểm/giây sau 2 giây kể từ lần tiêu Mana gần nhất.
- Quyền trượng đã có animation di chuyển/tấn công, beam tức thời tự khóa Enemy gần nhất trong góc phía trước và nút chuyển kiếm/quyền trượng; beam dừng ở vật cản và gây cùng damage một lần cho mọi Enemy nằm trên đường thẳng. Chỉ dùng được sau khi mở reward `staff`.
- Area Attack đã triển khai dưới dạng quả cầu tím tự khóa và bám Enemy gần nhất có đường nhìn: mở cùng Air Region, tốn 35 Mana, cooldown 8 giây, gây 150 sát thương cơ bản cho tất cả Enemy trong bán kính nổ khi chạm va chạm đầu tiên.
- Mobile Controls có joystick, Attack, Dash, Heal, Area Attack, đổi vũ khí và Interact; dùng chung InputMap với bàn phím. Phím test Area Attack trên PC là `Q`.
- Player hỗ trợ khóa điều khiển cinematic trong cảnh báo Boss.
- Khi chết, Player có thể hồi sinh tại Return Whirlpool, về Main Area hoặc Main Menu. Energy đang mang không mất.

### Region Và Boss

- Water Region có 13 BombFish tầm xa và 11 PaddleShark. BombFish ném bom theo vòng cung tới vị trí Player, bom cảnh báo 2 giây rồi nổ gây sát thương trong vùng tròn.
- `RegionEncounterController` theo dõi trực tiếp container quái, không đếm group `enemy` vì Boss cũng kế thừa Enemy.
- Boss không tồn tại khi map vừa tải. Sau cảnh báo, controller spawn đúng Boss của Region tại `BossSpawnPoint`.
- Cảnh báo hiện có overlay, camera pan, rung camera và vòng phép; **chưa có âm thanh cảnh báo/spawn**.
- `RegionVictoryController` đăng ký Boss spawn động, ghi nhận Boss vào progression, chờ nhặt boss Energy rồi mở victory dialog.
- Cả 5 Boss có AI riêng với telegraph và recovery ngắn. Turtle dùng đạn nước, laser xoay và lao mai; Panda dùng sóng đất, lăn lao và mưa đá; Minotaur dùng húc, chém sáng và cột sáng; Giant Bat dùng bổ nhào, lưỡi gió và lốc; Troll có bão đạn phân nhánh, loạt Fireball dày, bão đá gây choáng, hút sinh lực và chuỗi húc. Minotaur, Giant Bat và Troll tăng nhịp hoặc số đợt khi còn dưới 50% HP.

### Menu Và Settings

- Entry scene là Loading Screen, mặc định tải Main Menu.
- Main Menu có New Game, Continue và Exit.
- Settings hỗ trợ bật/tắt âm thanh, về Main Menu, thoát game và lưu audio setting tại `user://settings.cfg`.
- Main Area có BGM; Region/Boss chưa có bộ nhạc chiến đấu hoàn chỉnh.

## 5. Chưa Triển Khai Hoàn Chỉnh

Ưu tiên còn lại:

- Save/Load progression. Continue hiện chỉ chuyển tới Main Area, chưa đọc save.
- Save tối thiểu phải lưu Energy đang mang, Energy từng đá, Boss/Region/reward đã mở, weapon mode, cấp nâng chỉ số và game_completed.
- New Game hiện reset Energy nhưng chưa reset đầy đủ `ProgressionManager` và save data.
- Ending/victory screen sau Life Stone; hiện mới có signal và cờ hoàn thành.
- Âm thanh cảnh báo/spawn Boss và nhạc chiến đấu Region/Boss.
- Kỹ năng riêng, telegraph, recovery, phase và arena hoàn chỉnh cho từng Boss.
- Cân bằng sát thương, HP, Mana, cooldown và lượng Energy.
- Icon Energy chính thức; HUD hiện dùng hình Energy tạo bằng UI.

Chưa tự quyết định nếu chưa có yêu cầu rõ:

- Enemy respawn và khả năng farm Energy.
- Nội dung ending và khả năng chơi tiếp sau chiến thắng.
- Thông số cân bằng cuối cùng của vũ khí và Boss.

## 6. Kiến Trúc Quan Trọng

- `SceneLoader`: chuyển scene qua Loading Screen.
- `EnergyManager`: Energy Player đang mang.
- `ProgressionManager`: thứ tự đá, Energy từng đá, Boss, reward, Region và game completion.
- `Player`: combat, kỹ năng, vũ khí, death/respawn và cinematic lock.
- `enemy.gd` / `boss.gd`: combat cơ sở và Energy drop.
- `RegionEncounterController`: dọn quái -> cảnh báo -> spawn Boss.
- `RegionVictoryController`: Boss defeated -> progression -> reward pickup -> victory dialog.
- `Monk` + `EnergyStonePanel`: nộp Energy và kích hoạt đá; tương tác trực tiếp với đá mở `StatUpgradePanel` để nâng chỉ số.
- `Gatekeeper`: khóa/mở cổng và chuyển Region.

Progression hiện chỉ nằm trong bộ nhớ. Không đặt progression data trực tiếp trong `project.godot`; SaveManager sau này phải serialize trạng thái từ các manager.

## 7. Quy Tắc Phát Triển

1. Inspect code và đọc file này trước khi thay đổi gameplay/design.
2. Ưu tiên pattern, scene và component dùng chung đã có.
3. Không tự mở rộng scope hoặc quyết định các mục chưa chốt.
4. Không khôi phục thiết kế Core/Altar/Hub/Cây cũ.
5. Không sửa hoặc hoàn tác thay đổi không liên quan đang có trong working tree.
6. Test tối thiểu bằng Godot headless sau thay đổi gameplay; với progression/encounter cần thêm smoke test cho luồng chính.
7. Khi một feature chuyển từ planned sang implemented, cập nhật phần 4 và 5 thay vì thêm mô tả trùng lặp ở nơi khác.
8. Giữ kiến trúc dễ đọc vì đây là project học tập.
