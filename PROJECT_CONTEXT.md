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

- Player mở khóa phần thưởng progression mới như kỹ năng, vũ khí, nâng chỉ số hoặc chiến thắng.
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

Water Region được mở từ đầu. Các Region còn lại bị khóa và chỉ mở lần lượt khi viên đá của cấp trước đạt đủ mức Energy yêu cầu và Boss tương ứng đã bị đánh bại.

| Cấp | Region | Enemy | Boss | Energy Stone | Energy yêu cầu | Phần thưởng |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Water | Bomb Fish, Paddle Shark | Turtle | Water Stone | 100 | Kỹ năng hồi máu và Earth Region |
| 2 | Earth | Spider, Snake | Panda | Earth Stone | 150 | Quyền trượng tấn công xa và Light Region |
| 3 | Light | Hex Shaman, Torch Goblin | Minotaur | Light Stone | 200 | Kỹ năng tấn công diện rộng và Air Region |
| 4 | Air | Imp, Bumblebee | Giant Bat | Air Stone | 250 | Hệ thống nâng chỉ số và Life Region |
| 5 | Life | Thief, Spear Goblin | Troll | Life Stone | 300 | Hoàn thành trò chơi |

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

Prototype hình ảnh của 5 Viên Đá Năng Lượng đã được đặt thành vòng cung quanh Monk trong Main Area. Cả 5 dùng chung sprite sheet Gold Stone Highlight gồm 6 frame, chạy animation lấp lánh lặp ở 6 FPS và lệch frame khởi đầu. Shader chỉ đổi màu phần tinh thể: Water xanh lam, Earth xanh lá, Light vàng, Air tím và Life đỏ. Các viên đá hiện có collision vật lý nhưng chưa có logic tương tác, nạp Energy hoặc hiển thị tiến độ.

Main Area là nơi Player:

- Bắt đầu hoặc tiếp tục hành trình.
- Chọn cổng Region đã mở.
- Hồi sinh sau khi chết.
- Mang Energy dùng chung trở về và nhờ Monk nạp vào viên đá hiện tại trong tiến trình tuần tự.
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
- Monk là nơi Player gửi Energy đang mang theo vào Viên Đá Năng Lượng đang hoạt động trong tiến trình tuần tự.
- Giao diện của Monk hiển thị Energy đang mang, tiến độ viên đá hiện tại, trạng thái Boss tương ứng và phần thưởng sắp mở.
- Player có thể nộp từng phần. Giao diện hỗ trợ nộp toàn bộ lượng có thể hoặc nộp vừa đủ phần còn thiếu; lượng vượt quá sức chứa của đá vẫn được giữ lại.
- Sau khi Air Stone được kích hoạt, Monk đồng thời cung cấp giao diện đổi Energy đang mang để nâng chỉ số.

**Black Lancer, Blue Lancer, Purple Lancer, Red Lancer và Yellow Lancer** là 5 NPC giữ cổng:

- Mỗi Lancer phụ trách một cổng dẫn tới một trong 5 Region: Water, Earth, Light, Air hoặc Life.
- Khi Player đi vào phạm vi tương tác và chủ động trò chuyện, Lancer cho phép chuyển tới Region tương ứng.
- Việc chuyển Region phải sử dụng Loading Screen chung của project.
- Lancer chỉ cho phép dịch chuyển nếu Region tương ứng đã được mở khóa.
- Nếu Region còn khóa, Lancer thông báo điều kiện mở khóa và không chuyển scene.
- Thứ tự mở khóa Region vẫn là Water, Earth, Light, Air và Life.

Ánh xạ Gatekeeper đã chốt:

- Blue Lancer giữ cổng Water Region.
- Black Lancer giữ cổng Earth Region.
- Yellow Lancer giữ cổng Light Region.
- Purple Lancer giữ cổng Air Region.
- Red Lancer giữ cổng Life Region.

Cả 5 Lancer hiện đã có dialog xác nhận và đường dẫn tới Region tương ứng. Ở giai đoạn prototype, các cổng đang được bật để kiểm tra chuyển map; logic khóa/mở theo progression sẽ được bổ sung sau.

Lancer sử dụng dialog xác nhận Yes/No dùng chung. Khi Player ở trong vùng tương tác, phím Space ưu tiên mở dialog thay vì tấn công. Blue Lancer hỏi `"Bạn có muốn di chuyển đến Water Region không?"`; Yes chuyển map qua Loading Screen, No đóng dialog.

UI Monk và Energy Stone là **Planned / Chưa triển khai**. Thiết kế đã chốt gồm phần hội thoại nhiệm vụ, tiến độ đá, điều kiện Boss, thao tác nộp Energy và giao diện nâng chỉ số sau Air Stone.

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
9. Player trò chuyện với Monk và nộp Energy vào viên đá hiện tại; có thể nộp từng phần.
10. Viên đá chỉ được kích hoạt khi vừa đạt đủ Energy vừa xác nhận Boss của Region tương ứng đã bị đánh bại.
11. Khi kích hoạt, Player nhận phần thưởng của đá, cổng Region tiếp theo được mở và progression được lưu ngay lập tức.

Vòng lặp tiếp tục cho tới khi Life Stone đạt 300 Energy và Troll đã bị đánh bại.

Khi hai điều kiện cuối cùng hoàn tất, Life Stone kích hoạt nghi thức kết thúc, đặt game_completed thành true và mở màn hình chiến thắng. Nội dung hình ảnh, lời thoại và khả năng tiếp tục chơi sau ending vẫn cần thiết kế chi tiết.

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
- Chỉ viên đá hiện tại trong tiến trình tuần tự nhận Energy. Energy có thể được nộp từng phần và không thể làm tiến độ vượt mức tối đa.
- Energy dư sau khi đá đầy vẫn nằm trong lượng Energy Player đang mang.
- Energy đã nạp vào đá là vĩnh viễn và không thể rút lại.
- Đủ Energy chưa tự kích hoạt đá; Boss tương ứng cũng phải được đánh bại.
- Sau khi Air Stone được kích hoạt, Energy đang mang có thể được dùng để nâng chỉ số hoặc tiếp tục dành cho Life Stone.
- Player giữ nguyên Energy đang mang khi chết hoặc chuyển map; chỉ New Game mới reset về 0.
- Icon Energy sẽ được thiết kế hoặc chọn sau; chưa dùng `coin_icon` làm icon chính thức.

Các chi tiết chưa chốt:

- Energy được tự động nhặt hay cần Player chạm vào pickup.
- Enemy có respawn và tiếp tục rơi Energy hay không.
- Lượng Energy cụ thể của boss.

Không tự quyết định các chi tiết này khi chưa có yêu cầu rõ.

## 7. Mở Khóa Map Và Kỹ Năng

Mỗi Viên Đá Năng Lượng quản lý phần thưởng gameplay và việc mở cổng tiếp theo:

	Energy Stone đạt đủ mức Energy yêu cầu + Boss tương ứng đã bị đánh bại
	-> kích hoạt viên đá và mở khóa phần thưởng
	-> mở khóa cổng của Region tiếp theo

Quy tắc:

- Water Region mở sẵn khi bắt đầu New Game.
- Earth mở sau khi Water Stone đạt 100 Energy và Turtle đã bị đánh bại. Phần thưởng là kỹ năng hồi máu.
- Light mở sau khi Earth Stone đạt 150 Energy và Panda đã bị đánh bại. Phần thưởng là quyền trượng để tấn công từ xa.
- Air mở sau khi Light Stone đạt 200 Energy và Minotaur đã bị đánh bại. Phần thưởng là kỹ năng tấn công diện rộng.
- Life mở sau khi Air Stone đạt 250 Energy và Giant Bat đã bị đánh bại. Phần thưởng là hệ thống đổi Energy để nâng chỉ số.
- Life Stone kích hoạt khi đạt 300 Energy và Troll đã bị đánh bại. Đây là điều kiện chiến thắng progression chính.

Quy tắc phần thưởng đã chốt:

- **Hồi máu:** bị khóa khi bắt đầu New Game; Water Stone mở khóa kỹ năng. Giá trị cân bằng ban đầu là 25 Mana, hồi 30 HP và cooldown 5 giây.
- **Quyền trượng:** Earth Stone mở khóa một chế độ vũ khí thứ hai. Player có thể chuyển giữa kiếm cận chiến và quyền trượng tấn công xa. Đòn đánh thường của quyền trượng không tốn Mana nhưng phải yếu hơn hoặc chậm hơn kiếm; thông số cuối cùng sẽ được cân bằng khi triển khai combat.
- **Tấn công diện rộng:** Light Stone mở khóa kỹ năng gây sát thương quanh Player. Giá trị cân bằng ban đầu là 35 Mana, cooldown 8 giây và sát thương bằng 1.5 lần chỉ số Attack.
- **Nâng chỉ số:** Air Stone mở khóa giao diện tại Monk để tăng vĩnh viễn Max HP, Attack hoặc Max Mana. Mỗi lần tăng lần lượt cộng 10 Max HP, 2 Attack hoặc 10 Max Mana.
- Mỗi loại chỉ số có tối đa 5 cấp. Chi phí cho năm lần nâng cùng một chỉ số lần lượt là 50, 100, 150, 200 và 250 Energy.
- Nâng chỉ số chỉ tiêu Energy đang mang, không trừ tiến độ đã nạp vào bất kỳ viên đá nào.
- **Chiến thắng:** Life Stone đầy và Troll đã bị đánh bại sẽ kích hoạt ending và đánh dấu game đã hoàn thành.
## 8. Player Death Và Respawn

Khi Player chết trong một Region:

- Player bị khóa điều khiển, phát âm thanh thất bại và nhấp nháy trong 3 giây trước khi mở Game Over dialog.
- Dialog dùng chung hiển thị câu hỏi "Bạn muốn tiếp tục chiến đấu hay quay về đảo hồi sinh?" với 3 lựa chọn.
- Nút "Tiếp tục chiến đấu" hồi sinh Player với đầy HP tại Return Whirlpool của Region hiện tại; scene và trạng thái quái hiện tại được giữ nguyên.
- Nút "Quay về đảo hồi sinh" chuyển Player về Main Area qua Loading Screen.
- Nút "Về Main Menu" chuyển Player về res://scenes/ui/MainMenu.tscn qua Loading Screen.
- Region và cổng đã mở vẫn giữ nguyên trạng thái progression.
- Energy Player đang mang được giữ nguyên khi chết hoặc chuyển map; chỉ New Game mới reset về 0.

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
- Skill bắt đầu bị khóa và được bật theo progression. UI cuối cần có thao tác riêng cho hồi máu, tấn công diện rộng và chuyển đổi kiếm/quyền trượng; cách bố trí nút Android cụ thể sẽ được chốt khi triển khai.
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

Enemy hiện tại dùng chung base script và có 5 HP. Khi chết, mỗi enemy luôn rơi ngẫu nhiên 1-5 Energy dưới dạng pickup; pickup dùng Area2D để nhặt, GPUParticles2D để hiển thị, hút về Player khi đến gần và không tự biến mất.

EnergyManager.gd lưu lượng Energy đang mang trong AutoLoad để dữ liệu tồn tại khi chuyển map; New Game reset lượng này về 0.
HUD hiển thị Energy đang mang và cập nhật qua signal energy_changed. Energy chỉ giảm khi Monk gọi deposit_energy để nộp vào Energy Stone; phần giao diện nộp đá chưa triển khai.

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
- Khi boss bị hạ, boss phát signal defeated; Region phát âm thanh chiến thắng và mở dialog chúc mừng dùng chung.
- Victory dialog có ba lựa chọn: chơi lại Region hiện tại, quay về đảo hồi sinh (main.tscn), hoặc về MainMenu.tscn; mọi chuyển scene đi qua Loading Screen.
- RegionVictoryController.tscn là component tái sử dụng. Water Region đã được kết nối; các Region sau chỉ cần instance component và đặt replay_scene_path.
- Victory dialog phát pháo hoa trong khoảng 4,5 giây bằng VictoryFireworks.tscn; hiệu ứng vẫn chạy khi game pause và được giới hạn số particle cho Android.

Boss phải bị đánh bại để hoàn thành Region. Mỗi boss rơi cố định 30 Energy dưới dạng 6 pickup, mỗi pickup trị giá 5; Victory dialog chỉ mở sau khi Player đã nhặt hết phần thưởng boss.

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
- Chế độ vũ khí đang chọn và trạng thái quyền trượng đã mở.
- Cấp nâng Max HP, Attack và Max Mana.
- Trạng thái boss đã bị đánh bại.
- Trạng thái game_completed.
- Vị trí hoặc scene hồi sinh phù hợp nếu cần.

Phân chia trách nhiệm dự kiến:

- EnergyManager: quản lý Energy Player đang mang và thao tác cộng/trừ Energy.
- ProgressionManager: quản lý tiến độ 5 viên đá, Boss, Region, kỹ năng, phần thưởng và chiến thắng.
- PlayerUpgrades: cung cấp giá trị nâng Max HP, Attack và Max Mana cho mọi Player instance khi đổi map.
- SaveManager: ghi và khôi phục toàn bộ progression; save ngay sau khi nộp Energy, kích hoạt đá, nâng chỉ số hoặc hoàn thành game.

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
- Settings gameplay có nút bánh răng ở góc trên phải, hỗ trợ bật/tắt âm thanh, quay về Main Menu qua Loading Screen và thoát trò chơi.
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
5. **Đã hoàn thành:** Làm Settings bằng `AudioServer`, hỗ trợ bật/tắt âm thanh, quay về Main Menu, thoát trò chơi và lưu lựa chọn âm thanh.

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
