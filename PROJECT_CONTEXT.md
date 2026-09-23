# PROJECT_CONTEXT.md - Cây Nguyên Sinh

File này là **source of truth chính thức** của project từ thời điểm hiện tại.
Trước khi thay đổi gameplay, Main Area, Energy Stone, progression hoặc game design, phải đọc file này trước.

## 1. Tổng Quan Game

**Tên game:** Cây Nguyên Sinh.

**Thể loại:** 2D top-down action adventure, tập trung vào khám phá, chiến đấu, thu thập năng lượng và đánh boss theo từng cấp độ.

**Nền tảng mục tiêu:** Android.

**Engine:** Godot.

**Ngôn ngữ:** GDScript.

**Phong cách hình ảnh:** Pixel art giả tưởng, lấy cảm hứng từ thiên nhiên.

Game không phải open world. Game có một **Main Area** kết nối tới 5 Region thông qua 5 cổng. Người chơi hoàn thành các Region theo thứ tự cố định và độ khó tăng dần.

## 2. Cốt Truyện Chính Thức

Thế giới được duy trì bởi 5 **Viên Đá Năng Lượng**:

- Water Stone.
- Earth Stone.
- Light Stone.
- Air Stone.
- Life Stone.

Sau một biến cố, năng lượng trong các viên đá bị sinh vật của từng khu vực hấp thụ. Cả 5 viên đá bắt đầu ở mức năng lượng 0%.

Player là người bảo hộ được giao nhiệm vụ đi qua 5 Region, tiêu diệt quái vật, thu hồi Energy và mang Energy về Main Area để nạp lại cho từng Viên Đá Năng Lượng.

Khi một viên đá được nạp đủ mức Energy yêu cầu:

- Player mở khóa một kỹ năng đặc biệt mới.
- Region tiếp theo được mở khóa.
- Độ khó của hành trình tiếp tục tăng.

**Cây Nguyên Sinh không còn là đối tượng cần giải cứu.** Hệ thống thu thập Core và hồi sinh cây của thiết kế cũ đã bị loại bỏ khỏi cốt truyện chính thức.

## 3. Thứ Tự Cấp Độ

Tiến trình chính diễn ra theo thứ tự:

1. Water.
2. Earth.
3. Light.
4. Air.
5. Life.

Water Region được mở từ đầu. Các Region còn lại bị khóa và chỉ mở lần lượt khi viên đá của cấp trước đạt đủ mức Energy yêu cầu.

| Cấp | Region | Enemy | Boss | Energy Stone | Energy yêu cầu |
| --- | --- | --- | --- | --- | --- |
| 1 | Water | Bomb Fish, Paddle Shark | Turtle | Water Stone | 100 |
| 2 | Earth | Spider, Snake | Panda | Earth Stone | 150 |
| 3 | Light | Hex Shaman, Torch Goblin | Minotaur | Light Stone | 200 |
| 4 | Air | Imp, Bumblebee | Giant Bat | Air Stone | 250 |
| 5 | Life | Thief, Spear Goblin | Troll | Life Stone | 300 |

Trạng thái prototype Water Region:

- Scene được lưu tại `res://scenes/maps/WaterRegion.tscn`.
- Map hiện được nhân bản từ Air Region nên địa hình vẫn là placeholder và sẽ được tùy biến sau.
- Enemy hiện có trong map là Bomb Fish và Paddle Shark.
- Boss Turtle đã được đặt trong map.
- Tại điểm spawn có Return Whirlpool. Khi Player đứng trong vùng và nhấn `R`, dialog Yes/No dùng chung hỏi xác nhận quay về Main Area.
- Chọn Yes chuyển về `res://scenes/maps/main.tscn` qua Loading Screen; chọn No đóng dialog và giữ Player ở Water Region.
- Phím `R` chỉ là điều khiển prototype; bản Android sau này cần nút tương tác trên màn hình.

## 4. Main Area

Game không còn sử dụng Hub theo thiết kế cũ. Sau Main Menu, Player đi vào **Main Area** mới.

Main Area có:

- Player spawn point.
- 5 cổng dẫn tới Water, Earth, Light, Air và Life Region.
- 5 Viên Đá Năng Lượng tương ứng với 5 Region.
- Trạng thái khóa hoặc mở của từng cổng.
- Mức Energy đã nạp và mức Energy yêu cầu của từng viên đá.
- Các NPC prototype: Monk, Black Lancer, Blue Lancer, Purple Lancer, Red Lancer và Yellow Lancer.

Main Area là nơi Player:

- Bắt đầu hoặc tiếp tục hành trình.
- Chọn cổng Region đã mở.
- Hồi sinh sau khi chết.
- Mang Energy dùng chung trở về và nhờ Monk nạp vào viên đá được chọn.
- Nhận kỹ năng mới và mở khóa Region tiếp theo.

Scene Main Area hiện đang được xây dựng tại:

	res://scenes/maps/main.tscn

Các map gameplay hiện được tổ chức trong thư mục scenes/maps. Không tạo lại gameplay Hub, Altar hoặc Hub State từ thiết kế cũ.

Các scene NPC được tổ chức trong `res://scenes/npc/`. Monk hiện chỉ có animation idle và body collision. Năm Lancer dùng chung hệ thống Gatekeeper và vùng tương tác; Blue Lancer đã được liên kết với Water Region.

### Vai Trò NPC Trong Main Area

**Monk** là NPC chỉ dẫn chính:

- Giới thiệu mục tiêu và hướng dẫn gameplay cho Player.
- Khi Player lại gần và chủ động trò chuyện, Monk cho phép kiểm tra nhiệm vụ hiện tại.
- Hiển thị tiến độ của Region đang thực hiện, lượng Energy đã thu thập hoặc đã nạp và điều kiện còn thiếu để hoàn thành cấp độ.
- Monk là nơi Player gửi Energy đang mang theo vào từng Viên Đá Năng Lượng.
- Player chọn viên đá cần nạp; Energy dùng chung được chuyển từ lượng đang mang sang tiến độ riêng của viên đá đó.

**Black Lancer, Blue Lancer, Purple Lancer, Red Lancer và Yellow Lancer** là 5 NPC giữ cổng:

- Mỗi Lancer phụ trách một cổng dẫn tới một trong 5 Region: Water, Earth, Light, Air hoặc Life.
- Khi Player đi vào phạm vi tương tác và chủ động trò chuyện, Lancer cho phép chuyển tới Region tương ứng.
- Việc chuyển Region phải sử dụng Loading Screen chung của project.
- Lancer chỉ cho phép dịch chuyển nếu Region tương ứng đã được mở khóa.
- Nếu Region còn khóa, Lancer thông báo điều kiện mở khóa và không chuyển scene.
- Thứ tự mở khóa Region vẫn là Water, Earth, Light, Air và Life.

Ánh xạ Gatekeeper đã chốt một phần:

- Blue Lancer giữ cổng Water Region.
- Black, Purple, Red và Yellow Lancer chưa được gán Region cụ thể.

Không tự gán bốn Lancer còn lại cho Region khi chưa có xác nhận.

Lancer sử dụng dialog xác nhận Yes/No dùng chung. Khi Player ở trong vùng tương tác, phím Space ưu tiên mở dialog thay vì tấn công. Blue Lancer hỏi `"Bạn có muốn di chuyển đến Water Region không?"`; Yes chuyển map qua Loading Screen, No đóng dialog.

Hệ thống hội thoại nhiều nội dung, UI nhiệm vụ và tiến độ dành cho Monk là **TBD / Chưa thiết kế**.

## 5. Gameplay Loop Chính

Mỗi cấp độ sử dụng vòng lặp sau:

1. Player bắt đầu tại Main Area.
2. Player đi qua cổng của Region đang mở.
3. Player khám phá map và chiến đấu với enemy.
4. Enemy thường chết luôn rơi một lượng Energy ngẫu nhiên từ 1 đến 5.
5. Player thu thập Energy dùng chung; Energy không mang thuộc tính Water, Earth, Light, Air hoặc Life.
6. Player vào boss arena và đánh boss.
7. Player phải đánh bại boss để hoàn thành Region; lượng Energy cụ thể của boss chưa chốt.
8. Player mang Energy trở về Main Area.
9. Player trò chuyện với Monk và chọn viên đá để nạp Energy đang mang theo.
10. Khi viên đá đạt đủ mức Energy yêu cầu, Player mở khóa kỹ năng mới và Region tiếp theo.

Vòng lặp tiếp tục cho tới khi Life Stone đạt 300 Energy.

Nội dung kết thúc sau khi hoàn thành Life Region là **TBD / Chưa thiết kế**.

## 6. Hệ Thống Energy

Energy là tài nguyên progression chính của game.

Quy tắc đã chốt:

- Chỉ có một loại Energy dùng chung cho cả 5 Viên Đá Năng Lượng.
- Energy thu được không phụ thuộc Region hoặc loại enemy đã đánh bại.
- Enemy thường chết luôn rơi Energy; tỉ lệ rơi là 100%.
- Mỗi enemy thường rơi ngẫu nhiên một số nguyên từ 1 đến 5 Energy.
- Yếu tố ngẫu nhiên chỉ áp dụng cho số lượng Energy rơi ra, không áp dụng cho việc có rơi hay không.
- Player mang Energy dùng chung về Main Area và trò chuyện với Monk để nạp vào từng viên đá.
- Mỗi viên đá lưu tiến độ riêng; Energy đã nạp vào một viên đá không đồng thời tăng các viên đá khác.
- Mức Energy yêu cầu tăng thêm 50 theo từng cấp: Water 100, Earth 150, Light 200, Air 250 và Life 300.
- Icon Energy sẽ được thiết kế hoặc chọn sau; chưa dùng `coin_icon` làm icon chính thức.

Các chi tiết chưa chốt:

- Energy được tự động nhặt hay cần Player chạm vào pickup.
- Player giữ hay mất Energy đang mang theo khi chết.
- Enemy có respawn và tiếp tục rơi Energy hay không.
- Lượng Energy cụ thể của boss.
- Player nạp toàn bộ hay được chọn số lượng Energy mỗi lần nói chuyện với Monk.
- Cách xử lý Energy dư khi viên đá đạt mức tối đa.

Không tự quyết định các chi tiết này khi chưa có yêu cầu rõ.

## 7. Mở Khóa Map Và Kỹ Năng

Mỗi Viên Đá Năng Lượng quản lý hai phần thưởng progression:

	Energy Stone đạt đủ mức Energy yêu cầu
	-> mở khóa một kỹ năng đặc biệt
	-> mở khóa cổng của Region tiếp theo

Quy tắc:

- Water Region mở sẵn khi bắt đầu New Game.
- Earth mở sau khi Water Stone đạt 100 Energy.
- Light mở sau khi Earth Stone đạt 150 Energy.
- Air mở sau khi Light Stone đạt 200 Energy.
- Life mở sau khi Air Stone đạt 250 Energy.
- Life Stone đạt 300 Energy là mốc hoàn thành progression chính hiện tại.

Thiết kế cụ thể của 5 kỹ năng đặc biệt là **TBD / Chưa chốt**.

Không mặc định kỹ năng hiện có của Player là phần thưởng của một viên đá nếu chưa được xác nhận.

## 8. Player Death Và Respawn

Khi Player chết trong một Region:

- Dialog dùng chung hiển thị câu hỏi `"Bạn muốn tiếp tục chiến đấu hay quay về đảo hồi sinh?"`.
- Nút `Tiếp tục chiến đấu` hồi sinh Player với đầy HP tại Return Whirlpool của Region hiện tại; scene và trạng thái quái hiện tại được giữ nguyên.
- Nút `Quay về đảo hồi sinh` chuyển Player về Main Area qua Loading Screen.
- Region và cổng đã mở vẫn giữ nguyên trạng thái progression.
- Cách xử lý lượng Energy Player đang mang theo là **TBD / Chưa chốt**.

Không hồi sinh Player tại Hub cũ hoặc tại cây.

## 9. Player Gameplay

Prototype Player hiện có hoặc đang định hướng gồm:

- Di chuyển 8 hướng.
- Attack.
- Dash.
- HP.
- Receive Damage.
- Invincibility ngắn sau khi bị đánh.
- Knockback.
- Mana prototype với giá trị hiện tại/tối đa và API tiêu hao hoặc hồi Mana.
- Healing prototype.
- Death dialog với lựa chọn hồi sinh tại Return Whirlpool hoặc quay về Main Area.

Điều khiển bàn phím hiện tại chỉ dùng cho prototype. Sau này Android sẽ dùng:

- Virtual Joystick.
- Attack Button.
- Dash / Skill Button.

Mobile Controls prototype hiện đã được triển khai trong GameHUD:

- Joystick động bên trái điều khiển di chuyển 8 hướng.
- Attack, Dash và Skill nằm bên phải; Dash hiển thị cooldown.
- Skill hiện bị khóa vì thiết kế 5 kỹ năng đặc biệt vẫn chưa chốt.
- Interact Button chỉ xuất hiện khi Player ở gần một interactable như Gatekeeper hoặc Return Whirlpool.
- Bàn phím và cảm ứng dùng chung các InputMap action, không tách gameplay thành hai hệ thống.

Không thiết kế gameplay phụ thuộc cố định vào WASD hoặc các phím prototype.

## 10. Enemy

Enemy cơ bản có hoặc đang định hướng gồm:

- HP.
- Phát hiện Player.
- Chase Player.
- Attack Range.
- Attack Damage.
- Attack Cooldown.
- Receive Damage.
- Knockback.
- Death.
- Rơi Energy khi chết.

Enemy hiện tại dùng chung base script và có 5 HP. Hệ thống rơi Energy là **Planned / Chưa triển khai**.

## 11. Boss

Game có 5 boss:

- Water: Turtle.
- Earth: Panda.
- Light: Minotaur.
- Air: Giant Bat.
- Life: Troll.

Boss prototype hiện có:

- Scene và animation cơ bản.
- Logic kế thừa Enemy: phát hiện, truy đuổi, đánh gần, nhận sát thương và chết.
- HP và Attack Damage cao hơn enemy thường.
- Thanh máu boss lớn hiển thị trên màn hình khi boss phát hiện Player.

Boss phải bị đánh bại để hoàn thành Region. Lượng Energy cụ thể boss cung cấp là **TBD / Chưa chốt**.

Mỗi boss dự kiến có:

- 2-3 kiểu tấn công chính.
- Telegraph để Player có thể né.
- State machine đơn giản: Idle -> Choose Attack -> Attack -> Recovery -> Idle.
- Kỹ năng đặc biệt phù hợp với Region.
- Phase 2 nếu cần cho boss cuối hoặc boss nâng cao.

Kỹ năng riêng, boss arena và cơ chế rơi Energy của boss là **Planned / Chưa triển khai**.

## 12. Main Menu

Main Menu là màn hình giao diện có:

- NEW GAME.
- CONTINUE.
- EXIT.

Định hướng:

	NEW GAME
	-> reset 5 viên đá về 0%
	-> chỉ mở Water Region
	-> đưa Player vào Main Area

	CONTINUE
	-> đọc save
	-> khôi phục Energy, kỹ năng và cổng đã mở
	-> đưa Player vào Main Area

Main Menu và Main Area là hai scene có vai trò khác nhau. Không gọi Main Area là Main Menu.

## 13. Save Và Progression Data

Save System là **Planned / Chưa triển khai**.

Progression sau này cần lưu tối thiểu:

- Lượng Energy dùng chung Player đang mang theo.
- Lượng Energy đã nạp riêng vào Water, Earth, Light, Air và Life Stone.
- Region nào đã mở.
- Kỹ năng nào đã mở.
- Trạng thái boss đã bị đánh bại.
- Vị trí hoặc scene hồi sinh phù hợp nếu cần.

Không đặt progression data trực tiếp trong project.godot.

## 14. Nội Dung Thiết Kế Cũ Đã Loại Bỏ

Các nội dung sau không còn thuộc thiết kế chính thức:

- Giải cứu hoặc hồi sinh Cây Nguyên Sinh.
- 5 Lõi Sinh Thái hoặc Core.
- Mang Core về Altar.
- 6 trạng thái Hub: Dry, Water, Earth, Light, Air và Life.
- Hub thay đổi môi trường tích lũy theo Core.
- PrimordialTree progression.
- WaterAltar, EarthAltar, LightAltar, AirAltar và LifeAltar theo vai trò cũ.

Không tiếp tục xây dựng các hệ thống này nếu chưa có yêu cầu thiết kế mới.

## 15. Phạm Vi Hiện Tại

Đã có hoặc đang có trong project:

- Player prototype và combat cơ bản.
- HUD gameplay tái sử dụng đã có avatar, thanh HP và thanh Mana dùng khung SmallBar ở góc trên trái; HP/Mana được cập nhật qua signal từ Player.
- Settings gameplay có nút bánh răng ở góc trên phải, hỗ trợ bật/tắt âm thanh và thoát trò chơi.
- Trạng thái âm thanh được áp dụng qua `AudioServer` và lưu riêng trong `user://settings.cfg`.
- Main Area phát lặp `res://assets/audio/music/bgm_main_area.mp3` qua bus `Music`; các Region và boss sẽ dùng một bản nhạc chiến đấu chung được bổ sung sau.
- 10 enemy chia theo 5 Region.
- 5 boss scene và boss health bar cơ bản.
- 5 Region scene ở các mức độ hoàn thiện khác nhau.
- Main Area mới đang được xây dựng.
- Death dialog và hai nhánh respawn đã hoạt động trong Water Region.

Chưa triển khai:

- 5 cổng hoàn chỉnh và logic khóa/mở.
- 5 Viên Đá Năng Lượng.
- Energy pickup và hệ thống mang Energy.
- Nạp Energy tại Main Area.
- Kỹ năng đặc biệt và điều kiện mở khóa.
- Boss arena hoàn chỉnh.
- Save System.
- Kết thúc game sau Life Region.

### Roadmap Triển Khai Tiếp Theo

Thứ tự dưới đây có thể thay đổi khi có yêu cầu mới rõ ràng. Settings được ưu tiên làm trước WeaponData và Energy theo yêu cầu hiện tại:

1. **Đã hoàn thành:** Dựng giao diện HUD và kết nối thanh HP với health thật của Player.
2. **Đã hoàn thành:** Thêm Mana vào Player và kết nối thanh Mana với HUD.
3. Tạo `WeaponData` cùng logic đổi vũ khí và kết nối các ô vũ khí trên HUD.
4. Hoàn thiện Energy pickup, lượng Energy dùng chung đang mang và bộ đếm trên HUD. Icon Energy để thiết kế sau.
5. **Đã hoàn thành:** Làm Settings bằng `AudioServer`, hỗ trợ bật/tắt âm thanh, thoát trò chơi và lưu lựa chọn âm thanh.

## 16. Quy Tắc Phát Triển Project

Từ giờ khi có yêu cầu thêm feature hoặc sửa gameplay/design:

1. Inspect project trước.
2. Đọc PROJECT_CONTEXT.md.
3. Đối chiếu yêu cầu với context này.
4. Nếu yêu cầu mâu thuẫn với context, báo lại trước khi sửa.

Không được:

- Tự mở rộng scope.
- Tự thay đổi gameplay hoặc cốt truyện.
- Tự quyết định chi tiết đang được đánh dấu TBD.
- Sửa file không liên quan.
- Sửa Player, Enemy, Combat, movement, dash, Main Area hoặc Save System nếu chưa được yêu cầu rõ.

Ưu tiên kiến trúc đơn giản, dễ hiểu vì đây là project học tập.
