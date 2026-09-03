# PROJECT_CONTEXT.md - Cây Nguyên Sinh

File này là **source of truth chính thức** của project từ thời điểm hiện tại.
Trước khi thay đổi gameplay, Hub, Core, progression hoặc game design, phải đọc file này trước.

## 1. Tổng Quan Game

**Tên game:** Cây Nguyên Sinh

**Thể loại:** 2D top-down action adventure, tập trung vào khám phá ngắn và đánh boss theo từng khu vực.

**Nền tảng mục tiêu:** Android.

**Engine:** Godot.

**Ngôn ngữ:** GDScript.

**Phong cách hình ảnh:** Pixel art giả tưởng, lấy cảm hứng từ thiên nhiên.

Game không phải open world. Cấu trúc chính là một Hub trung tâm kết nối tới 5 Region.

## 2. Cốt Truyện

Thế giới tồn tại nhờ **Cây Nguyên Sinh**, một cây cổ thụ nằm ở trung tâm mạng lưới năng lượng tự nhiên.

Cây được duy trì bởi 5 **Lõi Sinh Thái**:

- Lõi Nước.
- Lõi Đất.
- Lõi Quang.
- Lõi Khí.
- Lõi Sinh.

Sau một biến cố năng lượng, 5 Lõi bị tách khỏi Cây Nguyên Sinh và rơi tới 5 khu vực khác nhau. Năng lượng của mỗi Lõi ảnh hưởng tới sinh vật mạnh nhất trong khu vực đó, khiến chúng phát triển bất thường và trở thành boss chiếm giữ Lõi.

Vì mất 5 Lõi, Cây Nguyên Sinh dần khô héo và môi trường trung tâm trở nên cằn cỗi.

Player là **linh hồn / nữ thần hộ mệnh của Cây Nguyên Sinh**. Nhiệm vụ của Player là rời Hub, đến từng Region, đánh bại boss, lấy lại Lõi và mang Lõi về để phục hồi Cây Nguyên Sinh.

## 3. Region, Boss Và Core

Game có 5 Region:

| Region | Boss | Core |
| --- | --- | --- |
| Hồ Cạn | Rùa Đá | Lõi Nước |
| Hẻm Rễ | Bọ Sừng Đất | Lõi Đất |
| Cao Nguyên Nắng | Bướm Tro | Lõi Quang |
| Thung Gió | Chim Gió | Lõi Khí |
| Vùng Ký Sinh | Khối Ký Sinh | Lõi Sinh |

Mỗi Region dự kiến có nhịp chơi:

1. Khám phá.
2. Gặp enemy.
3. Vào boss arena.
4. Đánh boss.
5. Nhận Core.
6. Quay về Hub.

Region system và boss hoàn chỉnh là **Planned / Not implemented yet**.

## 4. Gameplay Loop

Gameplay loop chính:

1. Player bắt đầu ở Hub.
2. Player tương tác với Altar để đi tới Region tương ứng.
3. Player khám phá và chiến đấu với enemy.
4. Player vào boss arena.
5. Player đánh bại boss.
6. Player nhận Core tương ứng.
7. Player quay về Hub và phục hồi Core tại Altar.
8. Hub và Cây Nguyên Sinh hồi sinh thêm một giai đoạn.

Lặp lại cho tới khi lấy đủ 5 Core.

## 5. Player Gameplay

Player là linh hồn / nữ thần hộ mệnh của Cây Nguyên Sinh.

Prototype Player hiện có hoặc đang định hướng gồm:

- Di chuyển 8 hướng.
- Attack.
- Dash.
- HP.
- Receive Damage.
- Invincibility ngắn sau khi bị đánh.
- Knockback.
- Death.

Điều khiển bàn phím hiện tại chỉ dùng cho prototype. Sau này Android sẽ dùng:

- Virtual Joystick.
- Attack Button.
- Dash / Skill Button.

Không thiết kế gameplay phụ thuộc cố định vào WASD.

## 6. Enemy Và Boss

Enemy cơ bản định hướng có:

- HP.
- Chase Player.
- Attack Range.
- Attack Damage.
- Attack Cooldown.
- Death.

Enemy hiện tại chỉ là prototype/base.

Boss system hoàn chỉnh là **Planned / Not implemented yet**.

Mỗi Boss dự kiến có:

- 2-3 kiểu tấn công chính.
- Telegraph / dấu hiệu báo trước để Player né.
- State machine đơn giản, ví dụ: Idle -> Choose Attack -> Attack -> Recovery -> Idle.
- Boss cuối hoặc boss nâng cao có thể có Phase 2.

## 7. Hub Là Một Scene Duy Nhất

Hub chỉ có một scene gameplay chính:

```text
res://scenes/hub/Hub.tscn
```

Không tạo 6 bản sao `Hub.tscn` cho 6 trạng thái nếu chưa được yêu cầu.

Cách hiểu đúng:

```text
Hub
+ Base Environment
+ environmental effects tích lũy
+ visual state của PrimordialTree
+ visual state của Altar/Core
```

Không hiểu:

```text
State 1 = một Hub scene riêng
State 2 = một Hub scene riêng
...
```

## 8. Logic 6 Hub State

Hub progression là **Planned / Not implemented yet**.

Định hướng enum:

```gdscript
enum HubState {
    DRY = 1,
    WATER = 2,
    EARTH = 3,
    LIGHT = 4,
    AIR = 5,
    LIFE = 6,
}
```

### DRY

Tiến trình: 0/5 Core.

Đây là trạng thái cơ sở của Hub:

- Đất khô cằn.
- Đất nứt.
- Cây Nguyên Sinh khô héo.
- Rễ cây khô.
- Không có lá.
- Không có hoa.
- Không có nước.
- Rất ít hoặc không có cỏ.
- 5 Altar đều trống.

`DRY` là base state, không bắt buộc phải tạo `DryLayer`.

### WATER

Sau khi Player mang về Lõi Nước:

- Giữ toàn bộ bố cục DRY.
- Xuất hiện nguồn nước.
- Dòng nước bắt đầu chảy.
- Rễ cây vươn về phía nguồn nước.
- Đất gần nguồn nước bớt khô.
- WaterAltar hiển thị Lõi Nước.

### EARTH

Sau khi Player có Lõi Nước + Lõi Đất:

- Giữ toàn bộ thay đổi WATER.
- Đất trở nên màu mỡ hơn.
- Vết nứt giảm.
- Cỏ bắt đầu mọc.
- Rêu xuất hiện.
- Cây/bụi nhỏ bắt đầu phát triển.
- Rễ cây khỏe hơn.
- EarthAltar hiển thị Lõi Đất.

### LIGHT

Sau khi Player có Water + Earth + Light:

- Giữ toàn bộ thay đổi WATER và EARTH.
- Cây Nguyên Sinh xuất hiện chồi non.
- Chưa có tán lá hoàn chỉnh.
- Thân và rễ có ánh sáng nhẹ.
- Môi trường sáng và ấm hơn.
- Có thể có hạt sáng nhỏ.
- LightAltar hiển thị Lõi Quang.

### AIR

Sau khi Player có Water + Earth + Light + Air:

- Giữ toàn bộ thay đổi trước đó.
- Lá mọc nhiều hơn.
- Tán cây bắt đầu hoàn chỉnh.
- Lá có thể chuyển động.
- Xuất hiện gió.
- Có thể có lá bay nhẹ.
- Môi trường sống động hơn.
- AirAltar hiển thị Lõi Khí.

### LIFE

Tiến trình: 5/5 Core.

Đây là trạng thái cuối:

- Giữ toàn bộ thay đổi trước đó.
- Cây Nguyên Sinh hồi sinh hoàn toàn.
- Tán cây lớn và xum xuê.
- Cây nở hoa.
- Mặt đất phủ cỏ.
- Cây cối xung quanh phát triển.
- Nước hoạt động đầy đủ.
- Ánh sáng ấm và linh thiêng.
- Có hoa, bướm và dấu hiệu sinh vật trở lại.
- Cả 5 Altar đều hiển thị Core.

## 9. Nguyên Tắc Tích Lũy Hub State

State mới không thay thế hoàn toàn State trước.

State mới luôn bằng:

```text
toàn bộ thay đổi trước đó
+ tác động của Core mới
```

Ví dụ:

```text
LIGHT = Water effects + Earth effects + Light effects
```

Không thiết kế State sau làm mất nước, cỏ, ánh sáng hoặc hiệu ứng đã xuất hiện ở State trước.

## 10. Thành Phần Giữ Nguyên Qua 6 State

Qua cả 6 Hub State, các thành phần sau phải nhất quán:

- Vị trí PrimordialTree.
- Vị trí 5 Altar.
- Player spawn.
- Kích thước Hub.
- Boundary.
- Lối đi chính.
- Camera.
- Layout gameplay.

State chỉ nên thay đổi:

- Art.
- Environment.
- VFX.
- Trạng thái cây.
- Trạng thái Core/Altar.

## 11. Năm Altar

5 object trung tâm quanh cây thống nhất gọi là:

- WaterAltar.
- EarthAltar.
- LightAltar.
- AirAltar.
- LifeAltar.

Không tự đổi Altar thành Gate hoặc Pedestal.

Mỗi Altar có thể đảm nhiệm hai vai trò:

```text
Trước khi lấy Core:
  điểm tương tác để đi tới Region tương ứng.

Sau khi lấy Core:
  nơi hiển thị Core đã được phục hồi.
```

Không cần tạo riêng Gate và Pedestal nếu chưa có yêu cầu khác.

Về sau, Altar có thể được chuẩn hóa thành object/scene tái sử dụng:

```text
res://scenes/hub/CoreAltar.tscn
res://scripts/hub/core_altar.gd
```

Phần này là **Planned / Not implemented yet**.

## 12. PrimordialTree

PrimordialTree là object trung tâm và quan trọng nhất của Hub.

PrimordialTree cần hỗ trợ nhiều visual state:

- Dry.
- Water.
- Earth.
- Light.
- Air.
- Life.

Không nhất thiết mỗi trạng thái phải là scene độc lập. Kiến trúc nên cho phép đổi visual theo `current_hub_state`.

Tree progression logic là **Planned / Not implemented yet**.

## 13. Định Hướng Hub Progression

Các file cốt lõi dự kiến cho Hub progression:

```text
res://scenes/hub/Hub.tscn
res://scripts/hub/hub.gd
res://scenes/hub/PrimordialTree.tscn
res://scripts/hub/primordial_tree.gd
res://scenes/hub/CoreAltar.tscn
res://scripts/hub/core_altar.gd
```

Các file/script này là **Planned / Not implemented yet**, trừ những file hiện đã tồn tại.

Save/progression data sẽ thiết kế sau và là **Planned / Not implemented yet**.

Không đặt Hub progression logic trong `project.godot`.

## 14. Main Menu

Main Menu hiện có:

- NEW GAME.
- CONTINUE.
- EXIT.

Định hướng sau này:

```text
NEW GAME -> reset progression -> bắt đầu ở Hub DRY
CONTINUE -> đọc save -> trở lại tiến trình trước đó
```

Save System là **Planned / Not implemented yet**.

`main_menu.gd` chỉ sử dụng progression khi làm logic NEW GAME / CONTINUE sau này.

## 15. Art Pipeline

Hub nên được tạo từ các thành phần art riêng, không biến toàn bộ Hub thành một ảnh duy nhất.

Ví dụ:

- Ground.
- PrimordialTree.
- Altar.
- Core.
- Water.
- Grass.
- Flowers.
- Rocks.
- VFX.

Mục tiêu là có thể bật/tắt hoặc thay đổi từng thành phần theo Hub State.

Hiện tại đang tập trung vào:

```text
HUB STATE 1 - DRY
```

Art đầu tiên của Hub DRY gồm:

- Background đất khô.
- Bệ/altar trống.
- Cây khô.

## 16. Quy Tắc Phát Triển Project

Từ giờ khi có yêu cầu thêm feature hoặc sửa gameplay/design:

1. Inspect project trước.
2. Đọc `PROJECT_CONTEXT.md`.
3. Đối chiếu yêu cầu với context này.
4. Nếu yêu cầu mâu thuẫn với context, báo lại trước khi sửa.

Không được:

- Tự mở rộng scope.
- Tự thay đổi gameplay/cốt truyện.
- Tự tạo hệ thống mới khi chưa được yêu cầu.
- Sửa file không liên quan.
- Sửa Player, Enemy, Combat, movement, dash, Hub gameplay hoặc Save System nếu chưa được yêu cầu rõ.

Ưu tiên kiến trúc đơn giản, dễ hiểu vì đây là project học tập.
