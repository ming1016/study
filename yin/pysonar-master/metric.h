// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


#ifndef CHROME_FRAME_METRICS_SERVICE_H_
#define CHROME_FRAME_METRICS_SERVICE_H_

#include <map>
#include <string>

#include "base/basictypes.h"
#include "base/lazy_instance.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram.h"
#include "base/synchronization/lock.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread_local.h"
#include "chrome/common/metrics/metrics_service_base.h"

class MetricsService : public MetricsServiceBase {
 public:
  static MetricsService* GetInstance();
  
  
  static void Start();
  static void Stop();
  
  void InitializeMetricsState();

  
  static const std::string& GetClientID();
  static const std::string recording;
  static const std::string active;
 private:
  MetricsService();
  virtual ~MetricsService();
  
  
  enum State {
    INITIALIZED,            
    ACTIVE,                 
    STOPPED,                
  };

  
  
  
  void SetRecording(bool enabled);

  
  
  
  
  
  
  
  
  void SetReporting(bool enabled);

  
  
  
  
  void HandleIdleSinceLastTransmission(bool in_idle);

  
  static void CALLBACK TransmissionTimerProc(HWND window, unsigned int message,
                                             unsigned int event_id,
                                             unsigned int time);

  
  
  void StartRecording();

  
  void StopRecording(bool save_log);

  
  
  
  void MakePendingLog();

  
  
  
  bool TransmissionPermitted() const;

  bool recording_active() const {
    return recording_active_;
  }

  bool reporting_active() const {
    return reporting_active_;
  }

  
  
  bool UploadData();

  
  static std::string GetVersionString();

  
  
  
  bool recording_active_;
  bool reporting_active_;

  
  
  bool user_permits_upload_;

  
  
  State state_;

  
  std::wstring server_url_;

  
  static std::string client_id_;

  
  int session_id_;

  static base::LazyInstance<base::ThreadLocalPointer<MetricsService> >
      g_metrics_instance_;

  base::PlatformThreadId thread_;

  
  bool initial_uma_upload_;

  
  int transmission_timer_id_;

  
  static base::Lock metrics_service_lock_;

  DISALLOW_COPY_AND_ASSIGN(MetricsService);
};

#endif  
