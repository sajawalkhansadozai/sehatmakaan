# Comprehensive Import Fixer Script
$ErrorActionPreference = "Continue"

$replacements = @{
    # Admin relative imports
    "import 'services/admin_mutations_service.dart'" = "import 'package:sehat_makaan_flutter/features/admin/services/admin_mutations_service.dart'"
    "import '../../../features/workshops/screens/admin/helpers/workshop_payment_helper.dart'" = "import 'package:sehat_makaan_flutter/features/admin/helpers/workshop_payment_helper.dart'"
    "import '../../../models/firebase_models.dart'" = "import 'package:sehat_makaan_flutter/shared/firebase_models.dart'"
    "import '../models/firebase_models.dart'" = "import 'package:sehat_makaan_flutter/shared/firebase_models.dart'"
    "import '../../../features/bookings/screens/admin/widgets/booking_card_widget.dart'" = "import 'package:sehat_makaan_flutter/features/admin/widgets/booking_card_widget.dart'"
    "import '../../../../../../screens/admin/utils/admin_styles.dart'" = "import 'package:sehat_makaan_flutter/features/admin/utils/admin_styles.dart'"
    "import '../../../../../../screens/admin/utils/admin_formatters.dart'" = "import 'package:sehat_makaan_flutter/features/admin/utils/admin_formatters.dart'"
    "import '../../../models/workshop_creator_model.dart'" = "import 'package:sehat_makaan_flutter/features/workshops/models/workshop_creator_model.dart'"
    "import '../../../models/workshop_creator_request_model.dart'" = "import 'package:sehat_makaan_flutter/features/workshops/models/workshop_creator_request_model.dart'"
    "import '../../../services/workshop_creator_service.dart'" = "import 'package:sehat_makaan_flutter/features/workshops/services/workshop_creator_service.dart'"
    "import '../../utils/constants.dart'" = "import 'package:sehat_makaan_flutter/core/constants/constants.dart'"
    "import '../utils/constants.dart'" = "import 'package:sehat_makaan_flutter/core/constants/constants.dart'"
    "import '../../utils/types.dart'" = "import 'package:sehat_makaan_flutter/core/constants/types.dart'"
    "import '../models/booking_model.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/models/booking_model.dart'"
    "import '../../models/booking_model.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/models/booking_model.dart'"
    "import '../../../models/booking_model.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/models/booking_model.dart'"
    "import '../services/booking_service.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/services/booking_service.dart'"
    "import '../../services/booking_service.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/services/booking_service.dart'"
    "import '../../../services/booking_service.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/services/booking_service.dart'"
    "import '../services/slot_availability_service.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/services/slot_availability_service.dart'"
    "import '../utils/duration_calculator.dart'" = "import 'package:sehat_makaan_flutter/features/bookings/utils/duration_calculator.dart'"
    "import '../../utils/dashboard_utils.dart'" = "import 'package:sehat_makaan_flutter/core/utils/dashboard_utils.dart'"
    "import '../../../utils/responsive_helper.dart'" = "import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart'"
    "import '../../utils/responsive_helper.dart'" = "import 'package:sehat_makaan_flutter/core/utils/responsive_helper.dart'"
}

Write-Host "Starting import fixes..." -ForegroundColor Cyan
$fileCount = 0
$fixCount = 0

Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $fileCount++
    $content = Get-Content $_.FullName -Raw
    $original = $content
    
    foreach($oldImport in $replacements.Keys) {
        $newImport = $replacements[$oldImport]
        $escapedOld = [regex]::Escape($oldImport)
        if($content -match $escapedOld) {
            $content = $content -replace $escapedOld, $newImport
            $fixCount++
        }
    }
    
    if($content -ne $original) {
        Set-Content $_.FullName $content -NoNewline
        Write-Host "Fixed: $($_.Name)" -ForegroundColor Green
    }
}

Write-Host "`nProcessed $fileCount files, made $fixCount fixes" -ForegroundColor Yellow
Write-Host "Running flutter analyze..." -ForegroundColor Cyan
flutter analyze
